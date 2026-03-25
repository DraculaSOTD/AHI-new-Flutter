import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// HUD Overlay widget for face scanning with animated states
class HUDOverlay extends StatefulWidget {
  final int haloState; // 0-4 for different states
  final String guideText;
  final String contextText;
  final String bpmValue;
  final Map<String, bool> completionStates;
  final VoidCallback? onBackTapped;
  
  const HUDOverlay({
    super.key,
    required this.haloState,
    required this.guideText,
    required this.contextText,
    this.bpmValue = '--',
    this.completionStates = const {},
    this.onBackTapped,
  });
  
  @override
  State<HUDOverlay> createState() => _HUDOverlayState();
}

class _HUDOverlayState extends State<HUDOverlay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Pulse animation for the halo
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Rotation animation for loading state
    _rotateController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_rotateController);
    
    _updateAnimations();
  }
  
  @override
  void didUpdateWidget(HUDOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.haloState != widget.haloState) {
      _updateAnimations();
    }
  }
  
  void _updateAnimations() {
    // Update animations based on halo state
    if (widget.haloState == 1 || widget.haloState == 2) {
      _pulseController.repeat(reverse: true);
      _rotateController.repeat();
    } else if (widget.haloState == 4) {
      _pulseController.stop();
      _rotateController.stop();
    } else {
      _pulseController.stop();
      _rotateController.stop();
    }
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }
  
  Color _getHaloColor() {
    switch (widget.haloState) {
      case 1:
        return AppColors.success; // Green - calibrating
      case 2:
        return AppColors.primaryBlue; // Blue - analyzing
      case 3:
        return AppColors.error; // Red - error/warning
      case 4:
        return AppColors.warning; // Gold - complete
      default:
        return AppColors.inactive; // Gray - idle
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Face guide oval with halo
        Center(
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: _buildFaceGuide(),
              );
            },
          ),
        ),
        
        // Top guide text
        Positioned(
          top: 80,
          left: 0,
          right: 0,
          child: _buildGuideTextPanel(),
        ),
        
        // Bottom metrics panel
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: _buildMetricsPanel(),
        ),
        
        // Back button
        if (widget.onBackTapped != null)
          Positioned(
            top: 50,
            left: 20,
            child: _buildBackButton(),
          ),
        
        // Completion badges
        Positioned(
          top: MediaQuery.of(context).size.height * 0.35,
          right: 20,
          child: _buildCompletionBadges(),
        ),
      ],
    );
  }
  
  Widget _buildFaceGuide() {
    final haloColor = _getHaloColor();
    
    return Container(
      width: 280,
      height: 360,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(180),
      ),
      child: Stack(
        children: [
          // Animated halo
          if (widget.haloState > 0)
            AnimatedBuilder(
              animation: _rotateAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: widget.haloState == 1 || widget.haloState == 2
                      ? _rotateAnimation.value
                      : 0,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: haloColor,
                        width: 4,
                      ),
                      borderRadius: BorderRadius.circular(180),
                      boxShadow: [
                        BoxShadow(
                          color: haloColor.withValues(alpha: 0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          
          // Corner markers
          ..._buildCornerMarkers(haloColor),
        ],
      ),
    );
  }
  
  List<Widget> _buildCornerMarkers(Color color) {
    return [
      // Top left
      Positioned(
        top: 20,
        left: 20,
        child: _buildCornerMarker(color, 0),
      ),
      // Top right
      Positioned(
        top: 20,
        right: 20,
        child: _buildCornerMarker(color, 90),
      ),
      // Bottom left
      Positioned(
        bottom: 20,
        left: 20,
        child: _buildCornerMarker(color, -90),
      ),
      // Bottom right
      Positioned(
        bottom: 20,
        right: 20,
        child: _buildCornerMarker(color, 180),
      ),
    ];
  }
  
  Widget _buildCornerMarker(Color color, double rotation) {
    return Transform.rotate(
      angle: rotation * math.pi / 180,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: color, width: 3),
            left: BorderSide(color: color, width: 3),
          ),
        ),
      ),
    );
  }
  
  Widget _buildGuideTextPanel() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.guideText,
              style: AppTypography.headingSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.contextText,
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMetricsPanel() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 40),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMetric(
              icon: Icons.favorite,
              value: widget.bpmValue,
              unit: 'BPM',
              color: Colors.red,
            ),
            Container(
              width: 1,
              height: 40,
              color: AppColors.divider,
            ),
            _buildMetric(
              icon: Icons.timer,
              value: '${widget.haloState > 0 ? _getProgress() : 0}',
              unit: '%',
              color: AppColors.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMetric({
    required IconData icon,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: AppTypography.headingSmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                unit,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildBackButton() {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(50),
      child: InkWell(
        onTap: widget.onBackTapped,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: const Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
            size: 24,
          ),
        ),
      ),
    );
  }
  
  Widget _buildCompletionBadges() {
    final badges = [
      {'key': 'bpm_isComplete', 'icon': Icons.favorite, 'label': 'HR'},
      {'key': 'rr_isComplete', 'icon': Icons.air, 'label': 'RR'},
      {'key': 'spo2_isComplete', 'icon': Icons.opacity, 'label': 'SpO2'},
      {'key': 'hrv_isComplete', 'icon': Icons.timeline, 'label': 'HRV'},
      {'key': 'si_isComplete', 'icon': Icons.psychology, 'label': 'SI'},
      {'key': 'bp_isComplete', 'icon': Icons.bloodtype, 'label': 'BP'},
    ];
    
    return Column(
      children: badges.map((badge) {
        final isComplete = widget.completionStates[badge['key']] ?? false;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isComplete
                  ? AppColors.success.withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isComplete ? AppColors.success : Colors.white,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  badge['icon'] as IconData,
                  color: isComplete ? Colors.white : Colors.white70,
                  size: 20,
                ),
                Text(
                  badge['label'] as String,
                  style: TextStyle(
                    color: isComplete ? Colors.white : Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
  
  int _getProgress() {
    // Calculate progress based on completion states
    final total = widget.completionStates.length;
    if (total == 0) return 0;
    
    final completed = widget.completionStates.values
        .where((isComplete) => isComplete)
        .length;
    
    return ((completed / total) * 100).round();
  }
}