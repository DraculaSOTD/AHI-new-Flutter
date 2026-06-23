import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show Rect, Size;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/services/logging_service.dart';

/// Streams an rPPG face-scan against Vastmindz's WebSocket vitals service in
/// **pure Dart** — no native librppg_core.so, no WebView, no JS bridge.
///
/// Wire protocol (from a working production capture):
///   wss://vm-production.xyz/vp/bgr_signal_socket
///     ?authToken=<master-token>&sex=male&age=48&weight=86&height=186
///   outbound frames: { "bgrSignal": [b1,g1,r1, b2,g2,r2, b3,g3,r3],
///                      "timestamp": <ms-since-epoch> }
///   inbound: progress / interference (best-effort), then a final session JSON.
///
/// The nine floats are B, G, R means over three skin ROIs: forehead, left
/// cheek, right cheek (the standard rPPG layout). All heavy DSP (HRV, BP,
/// stress, SpO2) happens server-side; the client only detects the face,
/// samples ROIs, and paces frames.
class VastmindzFaceScanService {
  VastmindzFaceScanService({
    required this.wsUrlBase,
    required this.authToken,
    required this.sex, // 'male' | 'female'
    required this.ageYears,
    required this.heightCm,
    required this.weightKg,
    this.measurementSeconds = 30,
    this.sendEveryNthFrame = 1,
  });

  final String wsUrlBase;
  final String authToken;
  final String sex;
  final int ageYears;
  final int heightCm;
  final int weightKg;
  final int measurementSeconds;
  final int sendEveryNthFrame;

  WebSocketChannel? _channel;
  StreamSubscription? _wsSub;
  FaceDetector? _detector;
  DateTime? _startedAt;
  int _frameCounter = 0;
  bool _busy = false;
  bool _closed = false;

  final _progressCtrl = StreamController<double>.broadcast();
  final _statusCtrl = StreamController<String>.broadcast();
  final _resultCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _liveDataCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _errorCtrl = StreamController<Object>.broadcast();

  int _facesFoundCount = 0;
  int _facesMissedCount = 0;

  /// 0.0 -> 1.0
  Stream<double> get progress => _progressCtrl.stream;

  /// Short status messages ("face not detected", "hold still", etc.)
  Stream<String> get status => _statusCtrl.stream;

  /// Final session JSON from the server.
  Stream<Map<String, dynamic>> get result => _resultCtrl.stream;

  /// Intermediate vitals updates the server emits during a measurement
  /// (e.g. running BPM, RR, SpO2, BP, stress). Schema isn't documented;
  /// the screen consumes whatever numeric fields appear.
  Stream<Map<String, dynamic>> get liveData => _liveDataCtrl.stream;

  /// WebSocket / processing errors (the service does not close on these,
  /// so the UI can decide whether to bail or keep waiting).
  Stream<Object> get errors => _errorCtrl.stream;

  Future<void> start() async {
    final url = '$wsUrlBase'
        '?authToken=$authToken'
        '&sex=$sex'
        '&age=$ageYears'
        '&weight=$weightKg'
        '&height=$heightCm';
    LoggingService.info('Opening Vastmindz WebSocket', tag: 'VastmindzFaceScan',
        context: {'url_base': wsUrlBase, 'sex': sex, 'age': ageYears});

    _channel = WebSocketChannel.connect(Uri.parse(url));
    _wsSub = _channel!.stream.listen(
      _onSocketMessage,
      onError: (Object e, StackTrace st) {
        LoggingService.error('WebSocket error', error: e, stackTrace: st,
            tag: 'VastmindzFaceScan');
        _errorCtrl.add(e);
      },
      onDone: () {
        LoggingService.info('WebSocket closed (server-initiated or local)',
            tag: 'VastmindzFaceScan');
      },
      cancelOnError: false,
    );

    // Speculative handshake: the SDK may send a control message before BGR
    // frames begin. Cheap to try; harmless if the server ignores unknown keys.
    try {
      _channel!.sink.add(jsonEncode({'type': 'START_MEASUREMENT', 'fps': 30}));
      LoggingService.info('Sent START_MEASUREMENT handshake',
          tag: 'VastmindzFaceScan');
    } catch (_) {}

    _detector = FaceDetector(
      options: FaceDetectorOptions(
        enableLandmarks: true,
        enableContours: false,
        enableClassification: false,
        enableTracking: false,
        performanceMode: FaceDetectorMode.fast,
      ),
    );

    _startedAt = DateTime.now();
    _frameCounter = 0;
  }

  /// Feed a `CameraImage` from a `CameraController.startImageStream`.
  ///
  /// `cameraSensorOrientation` and `deviceOrientation` are needed so ML Kit can
  /// interpret the YUV buffer correctly on Android. `isFrontCamera` flips the
  /// landmark X coordinates back into image space when needed.
  Future<void> processCameraFrame(
    CameraImage image, {
    required int cameraSensorOrientation,
    required bool isFrontCamera,
  }) async {
    if (_closed || _busy || _detector == null) return;
    _frameCounter++;
    if (_frameCounter % sendEveryNthFrame != 0) return;
    _busy = true;
    try {
      // Diagnostic: log the actual plane layout once per session.
      if (_frameCounter == 1) {
        LoggingService.info(
            'Camera plane layout: ${image.planes.length} planes, '
            'size=${image.width}x${image.height}, '
            'planeSizes=${image.planes.map((p) => p.bytes.length).toList()}, '
            'yStride=${image.planes[0].bytesPerRow}, '
            'uvStride=${image.planes.length > 1 ? image.planes[1].bytesPerRow : 0}, '
            'uvPixStride=${image.planes.length > 1 ? image.planes[1].bytesPerPixel : 0}',
            tag: 'VastmindzFaceScan');
      }

      // Always convert to a packed NV21 buffer ourselves. Samsung HAL ignores
      // ImageFormatGroup.nv21 and gives us 3-plane YUV_420_888; doing the
      // conversion here makes the rest of the pipeline format-agnostic.
      final nv21 = _toNv21(image);
      final rotation =
          InputImageRotationValue.fromRawValue(cameraSensorOrientation);
      if (rotation == null) {
        if (_frameCounter % 30 == 1) {
          LoggingService.warning(
              'Unknown sensor rotation $cameraSensorOrientation',
              tag: 'VastmindzFaceScan');
        }
        return;
      }
      final input = InputImage.fromBytes(
        bytes: nv21,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: image.width, // packed, no row padding
        ),
      );
      final faces = await _detector!.processImage(input);
      if (faces.isEmpty) {
        _facesMissedCount++;
        _statusCtrl.add('No face detected');
        if (_frameCounter % 30 == 1) {
          LoggingService.info(
              'No face yet (frame#$_frameCounter, missed=$_facesMissedCount)',
              tag: 'VastmindzFaceScan');
        }
        return;
      }
      _facesFoundCount++;
      final face = _largestFace(faces);
      final rois = _defineRois(face, image.width.toDouble(), image.height.toDouble());
      final bgrSignal =
          _averageBgrInRois(nv21, image.width, image.height, rois);
      if (bgrSignal == null) {
        if (_frameCounter % 30 == 1) {
          LoggingService.warning('ROI averaging returned null',
              tag: 'VastmindzFaceScan');
        }
        return;
      }

      final msg = jsonEncode({
        'bgrSignal': bgrSignal,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      _channel?.sink.add(msg);

      if (_frameCounter % 30 == 1) {
        LoggingService.info(
            'WS out frame#$_frameCounter (faces=$_facesFoundCount) bgr=${bgrSignal.map((v) => v.toStringAsFixed(1)).toList()}',
            tag: 'VastmindzFaceScan');
      }

      _updateProgress();
    } catch (e, st) {
      LoggingService.warning('Frame processing failed',
          tag: 'VastmindzFaceScan', context: {'error': e.toString()});
      if (kDebugMode) {
        debugPrintStack(stackTrace: st, label: 'VastmindzFaceScan');
      }
    } finally {
      _busy = false;
    }
  }

  /// Tear down WebSocket + face detector. Safe to call repeatedly.
  Future<void> dispose() async {
    _closed = true;
    try {
      await _wsSub?.cancel();
    } catch (_) {}
    try {
      await _channel?.sink.close();
    } catch (_) {}
    try {
      await _detector?.close();
    } catch (_) {}
    await _progressCtrl.close();
    await _statusCtrl.close();
    await _resultCtrl.close();
    await _liveDataCtrl.close();
    await _errorCtrl.close();
  }

  // ---------------------------------------------------------------------------
  // internals

  void _onSocketMessage(dynamic event) {
    try {
      final text = event is String
          ? event
          : (event is List<int> ? utf8.decode(event) : event.toString());

      // Log every incoming message raw (truncated) so we can decode the schema.
      final preview = text.length > 300 ? '${text.substring(0, 300)}…' : text;
      LoggingService.info('WS in: $preview', tag: 'VastmindzFaceScan');

      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) return;
      final type = decoded['messageType']?.toString() ?? '';
      final data = (decoded['data'] is Map<String, dynamic>)
          ? decoded['data'] as Map<String, dynamic>
          : const <String, dynamic>{};

      switch (type) {
        case 'MEASUREMENT_MEAN_DATA':
          final delta = <String, dynamic>{};
          final bpm = _validNum(data['bpm']);
          final rr = _validNum(data['rr']);
          final spo2 = _validNum(data['oxygen']);
          if (bpm != null) delta['bpm'] = bpm;
          if (rr != null) delta['rr'] = rr;
          if (spo2 != null) delta['spo2'] = spo2;
          final stressStatus = data['stressStatus'];
          if (stressStatus is String &&
              stressStatus.isNotEmpty &&
              stressStatus != 'NO_DATA') {
            delta['stressLabel'] = stressStatus;
          }
          if (delta.isNotEmpty) _liveDataCtrl.add(delta);
          break;

        case 'HRV_METRICS':
          final delta = <String, dynamic>{};
          final rmssd = _validNum(data['rmssd']);
          final sdnn = _validNum(data['sdnn']);
          final ibi = _validNum(data['ibi']);
          if (rmssd != null) delta['rmssd'] = rmssd;
          if (sdnn != null) delta['sdnn'] = sdnn;
          if (ibi != null) delta['ibi'] = ibi;
          final stressLabel = data['stress_label'];
          if (stressLabel is String && stressLabel.isNotEmpty) {
            delta['stressLabel'] = stressLabel;
          }
          if (delta.isNotEmpty) _liveDataCtrl.add(delta);
          break;

        case 'BLOOD_PRESSURE':
          final sys = _validNum(data['systolic']);
          final dia = _validNum(data['diastolic']);
          if (sys != null && dia != null) {
            _liveDataCtrl.add({'systolic': sys, 'diastolic': dia});
          }
          break;

        case 'MEASUREMENT_PROGRESS':
          // Server can emit overshoots (e.g. 168) on RECALIBRATING events.
          // Drop those — only forward values inside [0, 100].
          final p = data['progressPercent'];
          if (p is num && p >= 0 && p <= 100) {
            _progressCtrl.add((p / 100.0).clamp(0.0, 1.0));
          }
          break;

        case 'MEASUREMENT_STATUS':
          final code = data['statusCode']?.toString() ?? '';
          final msg = data['statusMessage']?.toString() ?? code;
          if (msg.isNotEmpty) _statusCtrl.add(msg);
          if (code.isNotEmpty) _liveDataCtrl.add({'statusCode': code});
          break;

        case 'INTERFERENCE_WARNING':
        case 'UNSTABLE_CONDITIONS_WARNING':
          _statusCtrl.add('Hold still — interference detected');
          break;

        case 'SIGNAL_QUALITY':
          final snr = (data['snr'] as num?)?.toDouble();
          if (snr != null && snr > -50) _liveDataCtrl.add({'snr': snr});
          break;

        case 'ACCESS_TOKEN':
        case 'MEASUREMENT_SIGNAL':
        case 'STRESS_INDEX':
          // Informational or always-sentinel during a session; no-op.
          break;

        default:
          // Unknown messageType — forward the whole envelope so the screen can
          // sniff it during dev. Cheap to keep.
          _liveDataCtrl.add(decoded);
      }
    } catch (e) {
      LoggingService.warning('Unparseable WS message',
          tag: 'VastmindzFaceScan', context: {'raw': event.toString()});
    }
  }

  void _updateProgress() {
    // Server's MEASUREMENT_PROGRESS is authoritative; this wall-clock fallback
    // only fires before the first MEASUREMENT_PROGRESS message arrives.
    if (_startedAt == null) return;
    final elapsed = DateTime.now().difference(_startedAt!).inMilliseconds /
        (measurementSeconds * 1000);
    final p = elapsed.clamp(0.0, 0.99);
    _progressCtrl.add(p);
  }

  num? _validNum(Object? v) {
    if (v is num && v.isFinite && v > 0) return v;
    if (v is String) {
      final parsed = num.tryParse(v);
      if (parsed != null && parsed.isFinite && parsed > 0) return parsed;
    }
    return null;
  }

  Face _largestFace(List<Face> faces) {
    faces.sort((a, b) =>
        (b.boundingBox.width * b.boundingBox.height)
            .compareTo(a.boundingBox.width * a.boundingBox.height));
    return faces.first;
  }

  /// Define 3 skin ROIs: forehead, left cheek, right cheek.
  /// All values are clamped to the image bounds.
  List<Rect> _defineRois(Face face, double imgW, double imgH) {
    final box = face.boundingBox;
    final lm = face.landmarks;
    final leftEye = lm[FaceLandmarkType.leftEye]?.position;
    final rightEye = lm[FaceLandmarkType.rightEye]?.position;
    final leftCheek = lm[FaceLandmarkType.leftCheek]?.position;
    final rightCheek = lm[FaceLandmarkType.rightCheek]?.position;

    final foreheadCenterX = (leftEye != null && rightEye != null)
        ? (leftEye.x + rightEye.x) / 2.0
        : box.center.dx;
    final eyeY = (leftEye != null && rightEye != null)
        ? (leftEye.y + rightEye.y) / 2.0
        : box.top + box.height * 0.4;
    final interEye = (leftEye != null && rightEye != null)
        ? (rightEye.x - leftEye.x).abs().toDouble()
        : box.width * 0.35;

    final foreheadW = interEye * 0.7;
    final foreheadH = interEye * 0.4;
    final foreheadTop = eyeY - interEye * 0.9;
    final forehead = Rect.fromLTWH(
      foreheadCenterX - foreheadW / 2,
      foreheadTop,
      foreheadW,
      foreheadH,
    );

    final cheekSize = box.width * 0.10;
    Rect _patchAround(double cx, double cy) => Rect.fromLTWH(
          cx - cheekSize / 2,
          cy - cheekSize / 2,
          cheekSize,
          cheekSize,
        );

    final left = leftCheek != null
        ? _patchAround(leftCheek.x.toDouble(), leftCheek.y.toDouble())
        : _patchAround(box.left + box.width * 0.25, box.center.dy);
    final right = rightCheek != null
        ? _patchAround(rightCheek.x.toDouble(), rightCheek.y.toDouble())
        : _patchAround(box.left + box.width * 0.75, box.center.dy);

    return [
      _clamp(forehead, imgW, imgH),
      _clamp(left, imgW, imgH),
      _clamp(right, imgW, imgH),
    ];
  }

  Rect _clamp(Rect r, double w, double h) {
    final l = r.left.clamp(0.0, w - 1);
    final t = r.top.clamp(0.0, h - 1);
    final rr = r.right.clamp(0.0, w);
    final bb = r.bottom.clamp(0.0, h);
    if (rr <= l || bb <= t) return Rect.zero;
    return Rect.fromLTRB(l, t, rr, bb);
  }

  /// Convert a `CameraImage` (NV21 or YUV_420_888) into a packed NV21 buffer:
  /// `width*height` Y bytes followed by `width*height/2` interleaved VU bytes.
  Uint8List _toNv21(CameraImage image) {
    final w = image.width;
    final h = image.height;
    final ySize = w * h;
    final uvSize = ySize ~/ 2;
    final out = Uint8List(ySize + uvSize);

    // 1) Luma plane — copy row-by-row to drop any padding (`bytesPerRow > w`).
    final yPlane = image.planes[0];
    final yStride = yPlane.bytesPerRow;
    if (yStride == w) {
      out.setRange(0, ySize, yPlane.bytes);
    } else {
      for (int row = 0; row < h; row++) {
        final src = row * yStride;
        out.setRange(row * w, row * w + w, yPlane.bytes, src);
      }
    }

    // 2) Chroma.
    if (image.planes.length >= 3) {
      // YUV_420_888: separate U and V planes, interleave as VU.
      final uPlane = image.planes[1];
      final vPlane = image.planes[2];
      final uStride = uPlane.bytesPerRow;
      final vStride = vPlane.bytesPerRow;
      final uPix = uPlane.bytesPerPixel ?? 1;
      final vPix = vPlane.bytesPerPixel ?? 1;
      final uBytes = uPlane.bytes;
      final vBytes = vPlane.bytes;
      int o = ySize;
      final halfW = w ~/ 2;
      final halfH = h ~/ 2;
      for (int row = 0; row < halfH; row++) {
        for (int col = 0; col < halfW; col++) {
          final vIdx = row * vStride + col * vPix;
          final uIdx = row * uStride + col * uPix;
          if (vIdx < vBytes.length) out[o] = vBytes[vIdx];
          o++;
          if (uIdx < uBytes.length) out[o] = uBytes[uIdx];
          o++;
        }
      }
    } else {
      // Already NV21 (single-plane) — copy chroma tail if present.
      final src = yPlane.bytes;
      if (src.length >= ySize + uvSize) {
        out.setRange(ySize, ySize + uvSize, src, ySize);
      }
    }
    return out;
  }

  /// Average BGR in each ROI of a packed NV21 buffer.
  /// Returns `[b1,g1,r1, b2,g2,r2, b3,g3,r3]`.
  List<double>? _averageBgrInRois(
    Uint8List nv21,
    int w,
    int h,
    List<Rect> rois,
  ) {
    final yLen = w * h;
    if (nv21.length < yLen + yLen ~/ 2) return null;

    final result = <double>[];
    for (final roi in rois) {
      if (roi.isEmpty) {
        result.addAll([0.0, 0.0, 0.0]);
        continue;
      }
      double sumB = 0, sumG = 0, sumR = 0;
      int count = 0;
      final x0 = roi.left.floor();
      final y0 = roi.top.floor();
      final x1 = roi.right.ceil().clamp(0, w);
      final y1 = roi.bottom.ceil().clamp(0, h);
      for (int y = y0; y < y1; y += 2) {
        for (int x = x0; x < x1; x += 2) {
          final Y = nv21[y * w + x];
          final uvRow = y ~/ 2;
          final uvCol = (x ~/ 2) * 2;
          final vIdx = yLen + uvRow * w + uvCol;
          final uIdx = vIdx + 1;
          if (uIdx >= nv21.length) continue;
          final V = nv21[vIdx] - 128;
          final U = nv21[uIdx] - 128;
          final r = (Y + 1.402 * V).clamp(0, 255);
          final g = (Y - 0.344136 * U - 0.714136 * V).clamp(0, 255);
          final b = (Y + 1.772 * U).clamp(0, 255);
          sumR += r;
          sumG += g;
          sumB += b;
          count++;
        }
      }
      if (count == 0) {
        result.addAll([0.0, 0.0, 0.0]);
      } else {
        result.add(sumB / count);
        result.add(sumG / count);
        result.add(sumR / count);
      }
    }
    return result;
  }
}

