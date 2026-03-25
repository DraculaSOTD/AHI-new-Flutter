//
//  AHI Native Scanning Page
//
//  Copyright (c) AHI. All rights reserved.
//

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../models/ahi_user_data.dart';
import '../../ahi_turnkey_bridge/tk_multiscan_bridge.dart';

enum TkScanType {
  body,
  face,
  finger,
}

class TkNativeScanningPage extends StatefulWidget {
  const TkNativeScanningPage({
    super.key,
    required this.scanType,
    required this.scanOptions,
    required this.onScanComplete,
    required this.onScanError,
    required this.onCancel,
  });

  final TkScanType scanType;
  final Map<String, dynamic> scanOptions;
  final Function(Map<String, dynamic>) onScanComplete;
  final Function(String) onScanError;
  final VoidCallback onCancel;

  @override
  State<TkNativeScanningPage> createState() => _TkNativeScanningPageState();
}

class _TkNativeScanningPageState extends State<TkNativeScanningPage>
    with TickerProviderStateMixin {
  late AnimationController _loadingController;
  late Animation<double> _loadingAnimation;
  
  bool _isScanning = false;
  bool _scanCompleted = false;
  String _statusMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();
    
    _loadingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );

    _initializeAndStartScan();
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  void _initializeAndStartScan() async {
    try {
      setState(() {
        _statusMessage = 'Checking permissions...';
      });

      // Check camera permission status (already granted in preparation screen)
      final permissionStatus = await Permission.camera.status;
      if (!permissionStatus.isGranted) {
        widget.onScanError('Camera permissions not granted');
        return;
      }

      await Future.delayed(const Duration(milliseconds: 500));
      
      setState(() {
        _statusMessage = 'Launching native scanner...';
        _isScanning = true;
      });

      await Future.delayed(const Duration(milliseconds: 1000));

      // Start the appropriate scan
      Map<String, dynamic> result;
      switch (widget.scanType) {
        case TkScanType.body:
          result = await TkMultiScanBridge.instance.startBodyScan(widget.scanOptions);
          break;
        case TkScanType.face:
          result = await TkMultiScanBridge.instance.startFaceScan(widget.scanOptions);
          break;
        case TkScanType.finger:
          result = await TkMultiScanBridge.instance.startFingerScan(widget.scanOptions);
          break;
      }

      setState(() {
        _scanCompleted = true;
        _statusMessage = 'Processing your scan results...';
      });

      // Provide haptic feedback
      HapticFeedback.lightImpact();

      // Short delay to ensure smooth transition from native view
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        widget.onScanComplete(result);
      }
    } catch (e) {
      setState(() {
        _isScanning = false;
        _statusMessage = 'Scan failed';
      });

      // Provide error haptic feedback
      HapticFeedback.heavyImpact();

      // Handle specific error types
      String errorMessage = e.toString();
      if (e is PlatformException) {
        switch (e.code) {
          case 'USER_CANCELLED':
            // User cancelled, just close
            widget.onCancel();
            return;
          case 'NO_CAMERA_PERMISSION':
            errorMessage = 'Camera permission is required for scanning';
            break;
          case 'RESOURCES_NOT_AVAILABLE':
            errorMessage = 'Scanning resources are not available. Please download them first.';
            break;
          case 'SDK_NOT_INITIALIZED':
            errorMessage = 'Scanner is not properly initialized. Please restart the app.';
            break;
          default:
            errorMessage = 'Scan failed: ${e.message ?? 'Unknown error'}';
            break;
        }
      }

      await Future.delayed(const Duration(milliseconds: 1500));
      
      if (mounted) {
        widget.onScanError(errorMessage);
      }
    }
  }

  String _getScanTypeTitle() {
    switch (widget.scanType) {
      case TkScanType.body:
        return 'Body Scanner';
      case TkScanType.face:
        return 'Face Scanner';
      case TkScanType.finger:
        return 'Finger Scanner';
    }
  }

  IconData _getScanTypeIcon() {
    switch (widget.scanType) {
      case TkScanType.body:
        return Icons.accessibility_new;
      case TkScanType.face:
        return Icons.face;
      case TkScanType.finger:
        return Icons.fingerprint;
    }
  }

  Color _getScanTypeColor() {
    switch (widget.scanType) {
      case TkScanType.body:
        return AppColors.primaryBlue;
      case TkScanType.face:
        return AppColors.primaryPurple;
      case TkScanType.finger:
        return AppColors.accentTeal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40), // Spacer for center alignment
                  Text(
                    _getScanTypeTitle(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      // If scanning is in progress, show confirmation dialog
                      if (_isScanning && !_scanCompleted) {
                        _showCancelConfirmationDialog();
                      } else {
                        widget.onCancel();
                      }
                    },
                  ),
                ],
              ),
            ),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Scan type icon with animation
                  AnimatedBuilder(
                    animation: _loadingAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scanCompleted ? 1.0 : (0.8 + (_loadingAnimation.value * 0.2)),
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: _getScanTypeColor().withValues(alpha: _scanCompleted ? 1.0 : 0.8),
                            borderRadius: BorderRadius.circular(60),
                            boxShadow: [
                              BoxShadow(
                                color: _getScanTypeColor().withValues(alpha: 0.3),
                                blurRadius: _scanCompleted ? 20 : 10,
                                spreadRadius: _scanCompleted ? 5 : 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            _scanCompleted ? Icons.check_circle : _getScanTypeIcon(),
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // Status message
                  Text(
                    _statusMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // Loading indicator
                  if (_isScanning && !_scanCompleted)
                    AnimatedBuilder(
                      animation: _loadingController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _loadingAnimation.value * 2 * 3.14159,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: CustomPaint(
                              painter: LoadingPainter(_loadingAnimation.value),
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 60),

                  // Instructions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      _getInstructions(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInstructions() {
    if (_scanCompleted) {
      switch (widget.scanType) {
        case TkScanType.body:
          return 'Analyzing your body measurements with AI. This takes just a few moments...';
        case TkScanType.face:
          return 'Analyzing your facial data with AI. This takes just a few moments...';
        case TkScanType.finger:
          return 'Analyzing your health metrics with AI. This takes just a few moments...';
      }
    }

    if (!_isScanning) {
      return 'Preparing scanner...';
    }

    switch (widget.scanType) {
      case TkScanType.body:
        return 'Follow the on-screen instructions to capture your body measurements. Keep your device steady and maintain good lighting.';
      case TkScanType.face:
        return 'Look directly at the camera and follow the instructions. Make sure your face is well-lit and clearly visible.';
      case TkScanType.finger:
        return 'Place your finger over the camera lens as instructed. Keep your finger still and maintain steady pressure.';
    }
  }

  void _showCancelConfirmationDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Scan?'),
        content: const Text('Are you sure you want to cancel the ongoing scan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Continue Scanning'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              widget.onCancel();
            },
            child: const Text('Cancel Scan'),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
          ),
        ],
      ),
    );
  }
}

class LoadingPainter extends CustomPainter {
  const LoadingPainter(this.progress);
  
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double startAngle = -3.14159 / 2; // Start from top
    final double sweepAngle = 2 * 3.14159 * progress;

    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}