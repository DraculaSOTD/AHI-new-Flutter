//
//  AHI Audio Service - Manages audio playback for scan feedback
//
//  Copyright (c) AHI. All rights reserved.
//

import 'package:just_audio/just_audio.dart';
import '../ahi_turnkey_assets/ahi_assets.dart';

class AHIAudioService {
  static final AHIAudioService _instance = AHIAudioService._internal();
  factory AHIAudioService() => _instance;
  AHIAudioService._internal();

  final Map<String, AudioPlayer> _players = {};

  /// Initialize audio service
  Future<void> initialize() async {
    // Preload commonly used sounds
    await _loadSound('beep1x', AHIAssets.beep1x);
    await _loadSound('beep3x', AHIAssets.beep3x);
  }

  /// Load a sound file
  Future<void> _loadSound(String key, String assetPath) async {
    try {
      final player = AudioPlayer();
      await player.setAsset(assetPath);
      _players[key] = player;
    } catch (e) {
      print('Warning: Failed to load sound $key: $e');
    }
  }

  /// Play single beep sound
  Future<void> playBeep() async {
    await _playSound('beep1x');
  }

  /// Play triple beep sound
  Future<void> playTripleBeep() async {
    await _playSound('beep3x');
  }

  /// Play a specific sound
  Future<void> _playSound(String key) async {
    final player = _players[key];
    if (player != null) {
      try {
        await player.seek(Duration.zero);
        await player.play();
      } catch (e) {
        print('Warning: Failed to play sound $key: $e');
      }
    }
  }

  /// Play scan start sound
  Future<void> playScanStart() async {
    await playBeep();
  }

  /// Play scan complete sound
  Future<void> playScanComplete() async {
    await playTripleBeep();
  }

  /// Play countdown beep
  Future<void> playCountdownBeep() async {
    await playBeep();
  }

  /// Play error sound (using single beep as fallback)
  Future<void> playError() async {
    await playBeep();
  }

  /// Set volume for all players
  Future<void> setVolume(double volume) async {
    for (final player in _players.values) {
      await player.setVolume(volume.clamp(0.0, 1.0));
    }
  }

  /// Mute all sounds
  Future<void> mute() async {
    await setVolume(0.0);
  }

  /// Unmute all sounds
  Future<void> unmute() async {
    await setVolume(1.0);
  }

  /// Dispose of all audio players
  Future<void> dispose() async {
    for (final player in _players.values) {
      await player.dispose();
    }
    _players.clear();
  }

  /// Check if audio is available
  bool get isAudioAvailable => _players.isNotEmpty;
}