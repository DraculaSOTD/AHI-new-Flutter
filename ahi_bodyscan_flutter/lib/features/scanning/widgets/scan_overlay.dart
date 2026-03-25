import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class ScanOverlay extends StatefulWidget {
  final String scanType;
  final String message;
  final bool showProgress;
  final double? progress;

  const ScanOverlay({
    super.key,
    required this.scanType,
    required this.message,
    this.showProgress = false,
    this.progress,
  });

  @override
  State<ScanOverlay> createState() => _ScanOverlayState();
}

class _ScanOverlayState extends State<ScanOverlay>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.backgroundWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated icon
              AnimatedBuilder(
                animation: _rotationAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationAnimation.value * 2 * 3.14159,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primaryPurple,
                                  AppColors.secondaryBlue,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getScanIcon(),
                              color: AppColors.textWhite,
                              size: 40,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // Scan type title
              Text(
                widget.scanType,
                style: AppTypography.headingMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Status message
              Text(
                widget.message,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // Progress indicator
              if (widget.showProgress) ...[
                SizedBox(
                  width: 200,
                  child: widget.progress != null
                      ? LinearProgressIndicator(
                          value: widget.progress,
                          backgroundColor: AppColors.borderLight,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryPurple,
                          ),
                        )
                      : LinearProgressIndicator(
                          backgroundColor: AppColors.borderLight,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryPurple,
                          ),
                        ),
                ),
                if (widget.progress != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    '${(widget.progress! * 100).toInt()}%',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ] else
                // Animated dots
                _buildAnimatedDots(),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getScanIcon() {
    switch (widget.scanType.toLowerCase()) {
      case 'body scan':
      case 'body':
        return Icons.accessibility_new;
      case 'face scan':
      case 'face':
        return Icons.face;
      case 'finger scan':
      case 'finger':
        return Icons.fingerprint;
      case 'downloading':
        return Icons.download;
      case 'initializing':
        return Icons.settings;
      default:
        return Icons.scanner;
    }
  }

  Widget _buildAnimatedDots() {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.33;
            final animationValue = (_rotationController.value - delay) % 1.0;
            final opacity = animationValue < 0.5 
                ? animationValue * 2 
                : (1.0 - animationValue) * 2;
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Opacity(
                opacity: opacity.clamp(0.3, 1.0),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Specialized overlay for camera-based scans
class CameraScanOverlay extends StatelessWidget {
  final String scanType;
  final String instruction;
  final VoidCallback? onCancel;
  final double? progress;

  const CameraScanOverlay({
    super.key,
    required this.scanType,
    required this.instruction,
    this.onCancel,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview would go here
          Container(
            color: Colors.black,
            child: const Center(
              child: Text(
                'Camera Preview',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          
          // Top overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  if (onCancel != null)
                    IconButton(
                      onPressed: onCancel,
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      scanType,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance for close button
                ],
              ),
            ),
          ),
          
          // Bottom overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).padding.bottom + 24,
                top: 24,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.9),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress bar
                  if (progress != null) ...[
                    Container(
                      width: double.infinity,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress!,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Instruction text
                  Text(
                    instruction,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  if (progress != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${(progress! * 100).toInt()}% complete',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}