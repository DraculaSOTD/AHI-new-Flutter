/// Scan-related constants for AHI BodyScan Flutter App
///
/// This file centralizes all magic numbers and configuration values
/// used across different scanning features (body, face, finger scans).
class ScanConstants {
  ScanConstants._(); // Private constructor to prevent instantiation

  // ========== Face Scan Constants ==========

  /// Maximum duration for a single face scan (in seconds)
  static const int faceScanMaxDurationSeconds = 60;

  /// Number of frames to track for face detection error window
  static const int faceDetectionErrorWindow = 5;

  /// Required minimum consecutive frames for stable face detection
  static const int faceDetectionMinConsecutiveFrames = 3;

  /// Break duration between consecutive face scans (in seconds)
  static const int faceScanBreakDurationSeconds = 60;

  /// Stabilization time after all vitals detected (in seconds)
  static const int vitalSignsStabilizationSeconds = 3;

  /// Safety buffer for platform view cleanup (in milliseconds)
  static const int platformViewCleanupBufferMs = 1000;

  // ========== Body Scan Constants ==========

  /// Timeout for body scan processing (in seconds)
  static const int bodyScanProcessingTimeoutSeconds = 120;

  // ========== Animation Durations ==========

  /// Standard short animation duration (in milliseconds)
  static const int animationShortMs = 300;

  /// Standard medium animation duration (in milliseconds)
  static const int animationMediumMs = 500;

  /// Standard long animation duration (in milliseconds)
  static const int animationLongMs = 1000;

  /// HUD state transition duration (in seconds)
  static const int hudTransitionSeconds = 2;

  /// Face mesh animation duration (in seconds)
  static const int faceMeshAnimationSeconds = 2;

  /// Particle background animation (in seconds)
  static const int particleBackgroundAnimationSeconds = 1;

  // ========== Timeout Constants ==========

  /// Short delay for UI updates (in seconds)
  static const int shortDelaySeconds = 1;

  /// Medium delay for transitions (in seconds)
  static const int mediumDelaySeconds = 2;

  /// Long delay for processing (in seconds)
  static const int longDelaySeconds = 5;

  /// Periodic state check interval (in seconds)
  static const int stateCheckIntervalSeconds = 1;

  // ========== SDK Configuration ==========

  /// Default FPS for SDK operations
  static const int defaultFPS = 30;

  /// WebSocket connection timeout (in seconds)
  static const int websocketTimeoutSeconds = 10;

  /// Max retry attempts for SDK operations
  static const int maxRetryAttempts = 3;

  /// Retry delay between SDK operations (in milliseconds)
  static const int retryDelayMs = 1000;

  // ========== UI Constants ==========

  /// PPG signal chart display point count
  static const int ppgSignalMaxPoints = 75;

  /// Default mesh opacity (0-100)
  static const int defaultMeshOpacity = 70;

  /// Corner guide size for camera overlay (in pixels)
  static const double cornerGuideSize = 30.0;

  /// Corner guide margin from edge (in pixels)
  static const double cornerGuideMargin = 20.0;

  // ========== Validation Constants ==========

  /// Required number of completed scans for assessment
  static const int requiredScanCount = 3;

  /// Minimum confidence threshold for measurements (0.0 - 1.0)
  static const double minConfidenceThreshold = 0.75;

  // ========== Helper Methods ==========

  /// Get Duration object for face scan max duration
  static Duration get faceScanMaxDuration =>
      Duration(seconds: faceScanMaxDurationSeconds);

  /// Get Duration object for face scan break
  static Duration get faceScanBreakDuration =>
      Duration(seconds: faceScanBreakDurationSeconds);

  /// Get Duration object for vital signs stabilization
  static Duration get vitalSignsStabilization =>
      Duration(seconds: vitalSignsStabilizationSeconds);

  /// Get Duration object for platform view cleanup buffer
  static Duration get platformViewCleanupBuffer =>
      Duration(milliseconds: platformViewCleanupBufferMs);

  /// Get Duration object for short delay
  static Duration get shortDelay => Duration(seconds: shortDelaySeconds);

  /// Get Duration object for medium delay
  static Duration get mediumDelay => Duration(seconds: mediumDelaySeconds);

  /// Get Duration object for long delay
  static Duration get longDelay => Duration(seconds: longDelaySeconds);

  /// Get Duration object for state check interval
  static Duration get stateCheckInterval =>
      Duration(seconds: stateCheckIntervalSeconds);

  /// Get Duration object for HUD transition
  static Duration get hudTransition => Duration(seconds: hudTransitionSeconds);

  /// Get Duration object for face mesh animation
  static Duration get faceMeshAnimation =>
      Duration(seconds: faceMeshAnimationSeconds);

  /// Get Duration object for particle background animation
  static Duration get particleBackgroundAnimation =>
      Duration(seconds: particleBackgroundAnimationSeconds);
}
