import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import '../../../core/services/logging_service.dart';

/// Metronome service for step test
///
/// Plays audio beats at a specified BPM to guide the user's stepping pace.
/// Standard YMCA step test protocol:
/// - Men: 24 steps/min = 96 BPM (4 beats per cycle)
/// - Women: 22 steps/min = 88 BPM (4 beats per cycle)
class MetronomeService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _beatTimer;
  bool _isPlaying = false;
  int _currentBpm = 96;
  int _beatCount = 0;

  // Callbacks
  ValueChanged<int>? onBeat;
  VoidCallback? onCycleComplete;

  bool get isPlaying => _isPlaying;
  int get currentBpm => _currentBpm;
  int get beatCount => _beatCount;

  MetronomeService({
    this.onBeat,
    this.onCycleComplete,
  });

  /// Start the metronome at specified BPM
  ///
  /// Standard values:
  /// - 96 BPM for men (24 steps/min)
  /// - 88 BPM for women (22 steps/min)
  Future<void> start({int bpm = 96}) async {
    if (_isPlaying) {
      LoggingService.warning('Metronome already playing', tag: 'Metronome');
      return;
    }

    _currentBpm = bpm;
    _beatCount = 0;
    _isPlaying = true;

    // Calculate interval between beats in milliseconds
    final intervalMs = (60000 / bpm).round();

    LoggingService.info('Starting metronome', tag: 'Metronome', context: {'bpm': bpm, 'intervalMs': intervalMs});

    // Load the beat sound
    await _loadBeatSound();

    // Start the timer
    _beatTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      _playBeat();
    });

    // Play first beat immediately
    _playBeat();
  }

  /// Stop the metronome
  Future<void> stop() async {
    if (!_isPlaying) return;

    _beatTimer?.cancel();
    _beatTimer = null;
    _isPlaying = false;
    await _audioPlayer.stop();

    LoggingService.info('Metronome stopped', tag: 'Metronome', context: {'totalBeats': _beatCount});
  }

  /// Pause the metronome
  void pause() {
    if (!_isPlaying) return;

    _beatTimer?.cancel();
    _beatTimer = null;
    _isPlaying = false;

    LoggingService.info('Metronome paused', tag: 'Metronome', context: {'beatCount': _beatCount});
  }

  /// Resume the metronome
  Future<void> resume() async {
    if (_isPlaying) return;

    _isPlaying = true;
    final intervalMs = (60000 / _currentBpm).round();

    _beatTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      _playBeat();
    });

    LoggingService.info('Metronome resumed', tag: 'Metronome', context: {'beatCount': _beatCount});
  }

  /// Change BPM on the fly
  Future<void> changeBpm(int newBpm) async {
    if (newBpm == _currentBpm) return;

    final wasPlaying = _isPlaying;

    if (wasPlaying) {
      await stop();
    }

    _currentBpm = newBpm;

    if (wasPlaying) {
      await start(bpm: newBpm);
    }

    LoggingService.info('Changed BPM', tag: 'Metronome', context: {'newBpm': newBpm});
  }

  /// Load the beat sound
  Future<void> _loadBeatSound() async {
    try {
      // Try to load custom beat sound from assets
      await _audioPlayer.setSource(AssetSource('sounds/metronome_beat.mp3'));
    } catch (e) {
      LoggingService.warning('Could not load custom beat sound: $e', tag: 'Metronome');
      // Fallback: use system beep
      // We'll use a simple tone generation as fallback
    }
  }

  /// Play a single beat
  Future<void> _playBeat() async {
    _beatCount++;

    // Trigger callback
    if (onBeat != null) {
      onBeat!(_beatCount);
    }

    // Check if we completed a full stepping cycle (4 beats)
    if (_beatCount % 4 == 0 && onCycleComplete != null) {
      onCycleComplete!();
    }

    // Play the sound
    try {
      await _audioPlayer.resume();
      await _audioPlayer.seek(Duration.zero);
    } catch (e) {
      // If audio player fails, use system beep as fallback
      SystemSound.play(SystemSoundType.click);
    }
  }

  /// Get recommended BPM based on gender and age
  ///
  /// Standard YMCA protocol:
  /// - Men: 24 steps/min (96 BPM)
  /// - Women: 22 steps/min (88 BPM)
  static int getRecommendedBpm({required String gender, int? age}) {
    // Standard protocol doesn't vary by age, only gender
    if (gender.toLowerCase() == 'male' || gender.toLowerCase() == 'm') {
      return 96; // 24 steps/min × 4 beats per step
    } else {
      return 88; // 22 steps/min × 4 beats per step
    }
  }

  /// Calculate total steps from beat count
  int getTotalSteps() {
    // Each stepping cycle = 4 beats = 1 complete step (up-up-down-down)
    return (_beatCount / 4).floor();
  }

  /// Calculate steps per minute from beat count and elapsed time
  double getStepsPerMinute(Duration elapsed) {
    final totalSteps = getTotalSteps();
    final minutes = elapsed.inSeconds / 60;
    if (minutes == 0) return 0;
    return totalSteps / minutes;
  }

  /// Dispose resources
  void dispose() {
    _beatTimer?.cancel();
    _audioPlayer.dispose();
  }
}

/// Metronome beat patterns for different step test protocols
enum StepTestProtocol {
  ymcaMen,      // 96 BPM (24 steps/min)
  ymcaWomen,    // 88 BPM (22 steps/min)
  harvard,      // 120 BPM (30 steps/min) - more intense
  queens,       // 88-96 BPM based on gender
}

extension StepTestProtocolExtension on StepTestProtocol {
  int getBpm({String gender = 'male'}) {
    switch (this) {
      case StepTestProtocol.ymcaMen:
        return 96;
      case StepTestProtocol.ymcaWomen:
        return 88;
      case StepTestProtocol.harvard:
        return 120;
      case StepTestProtocol.queens:
        return gender.toLowerCase() == 'male' ? 96 : 88;
    }
  }

  String get name {
    switch (this) {
      case StepTestProtocol.ymcaMen:
        return 'YMCA (Men)';
      case StepTestProtocol.ymcaWomen:
        return 'YMCA (Women)';
      case StepTestProtocol.harvard:
        return 'Harvard Step Test';
      case StepTestProtocol.queens:
        return 'Queens College';
    }
  }

  String get description {
    switch (this) {
      case StepTestProtocol.ymcaMen:
        return '24 steps/minute (96 BPM) - Standard for men';
      case StepTestProtocol.ymcaWomen:
        return '22 steps/minute (88 BPM) - Standard for women';
      case StepTestProtocol.harvard:
        return '30 steps/minute (120 BPM) - High intensity';
      case StepTestProtocol.queens:
        return 'Gender-based: 24 steps/min (M), 22 steps/min (F)';
    }
  }
}
