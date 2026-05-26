//
//  AHI Body Scan Results Page
//
//  Copyright (c) AHI. All rights reserved.
//

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../models/ahi_user_data.dart';

class TkBodyScanResultsPage extends StatefulWidget {
  const TkBodyScanResultsPage({
    super.key,
    required this.results,
    required this.onClose,
    this.onSaveResults,
    this.onHealthAssessment,
  });

  final TkBodyScanResultData results;
  final VoidCallback onClose;
  final Function(TkBodyScanResultData)? onSaveResults;
  final VoidCallback? onHealthAssessment;

  @override
  State<TkBodyScanResultsPage> createState() => _TkBodyScanResultsPageState();
}

class _TkBodyScanResultsPageState extends State<TkBodyScanResultsPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    // Provide haptic feedback for successful scan
    HapticFeedback.lightImpact();
    
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: widget.onClose,
        ),
        title: const Text(
          'Scan Results',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (widget.onHealthAssessment != null)
            IconButton(
              icon: const Icon(Icons.health_and_safety, color: AppColors.primaryPurple),
              onPressed: widget.onHealthAssessment,
              tooltip: 'Health Assessment',
            ),
          if (widget.onSaveResults != null)
            IconButton(
              icon: const Icon(Icons.save_alt, color: AppColors.primaryPurple),
              onPressed: () => widget.onSaveResults!(widget.results),
              tooltip: 'Save Results',
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Success header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryPurple.withValues(alpha: 0.1),
                        AppColors.primaryBlue.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Scan Complete!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Scanned on ${_formatDate(widget.results.scanDate)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Body measurements section
                _buildSectionHeader('Body Measurements'),
                const SizedBox(height: 12),
                _buildMeasurementCard('Chest', widget.results.chestInCm, 'cm'),
                _buildMeasurementCard('Waist', widget.results.waistInCm, 'cm'),
                _buildMeasurementCard('Hips', widget.results.hipsInCm, 'cm'),
                _buildMeasurementCard('Thigh', widget.results.thighInCm, 'cm'),
                _buildMeasurementCard('Inseam', widget.results.inseamInCm, 'cm'),

                const SizedBox(height: 24),

                // Body composition section
                _buildSectionHeader('Body Composition'),
                const SizedBox(height: 12),
                _buildMeasurementCard('Body Fat', widget.results.bodyfatInPercent, '%'),
                _buildMeasurementCard('Predicted Weight', widget.results.weightPredictInKg, 'kg'),
                if (widget.results.muscleMassInKg != null)
                  _buildMeasurementCard('Muscle Mass', widget.results.muscleMassInKg, 'kg'),
                if (widget.results.fatMassInKg != null)
                  _buildMeasurementCard('Fat Mass', widget.results.fatMassInKg, 'kg'),

                const SizedBox(height: 24),

                // Health ratios section
                if (widget.results.waistToHeightRatio != null || widget.results.waistToHipRatio != null) ...[
                  _buildSectionHeader('Health Ratios'),
                  const SizedBox(height: 12),
                  if (widget.results.waistToHeightRatio != null)
                    _buildRatioCard(
                      'Waist-to-Height Ratio',
                      widget.results.waistToHeightRatio!,
                      _getWaistHeightRatioStatus(widget.results.waistToHeightRatio!),
                    ),
                  if (widget.results.waistToHipRatio != null)
                    _buildRatioCard(
                      'Waist-to-Hip Ratio',
                      widget.results.waistToHipRatio!,
                      _getWaistHipRatioStatus(widget.results.waistToHipRatio!, widget.results.biologicalSex),
                    ),
                  const SizedBox(height: 24),
                ],

                // User info section
                _buildSectionHeader('Scan Details'),
                const SizedBox(height: 12),
                _buildInfoCard(),

                // Health Assessment CTA
                if (widget.onHealthAssessment != null) ...[
                  const SizedBox(height: 24),
                  _buildHealthAssessmentCTA(),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildMeasurementCard(String label, num? value, String unit) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            value != null ? '${value.toStringAsFixed(1)} $unit' : 'N/A',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryPurple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatioCard(String label, num ratio, RatioStatus status) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: status.color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                ratio.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: status.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: status.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow('Gender', widget.results.biologicalSex.toUpperCase()),
          _buildInfoRow('Height', '${widget.results.heightInCm.toStringAsFixed(0)} cm'),
          _buildInfoRow('Weight', '${widget.results.weightInKg.toStringAsFixed(1)} kg'),
          _buildInfoRow('Age', '${widget.results.ageInYears} years'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthAssessmentCTA() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryPurple.withValues(alpha: 0.1),
            AppColors.primaryBlue.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryPurple.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.health_and_safety,
            size: 48,
            color: AppColors.primaryPurple,
          ),
          const SizedBox(height: 12),
          Text(
            'Get Your Complete Health Assessment',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Complete a brief health survey to get personalized insights and recommendations based on your scan results.',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onHealthAssessment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Start Health Assessment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  RatioStatus _getWaistHeightRatioStatus(num ratio) {
    if (ratio < 0.4) {
      return RatioStatus('Underweight', AppColors.warning);
    } else if (ratio <= 0.5) {
      return RatioStatus('Healthy', AppColors.success);
    } else if (ratio <= 0.6) {
      return RatioStatus('Overweight', AppColors.warning);
    } else {
      return RatioStatus('Obese', AppColors.error);
    }
  }

  RatioStatus _getWaistHipRatioStatus(num ratio, String gender) {
    if (gender.toLowerCase() == 'male') {
      if (ratio <= 0.9) {
        return RatioStatus('Low Risk', AppColors.success);
      } else if (ratio <= 1.0) {
        return RatioStatus('Moderate Risk', AppColors.warning);
      } else {
        return RatioStatus('High Risk', AppColors.error);
      }
    } else {
      if (ratio <= 0.8) {
        return RatioStatus('Low Risk', AppColors.success);
      } else if (ratio <= 0.85) {
        return RatioStatus('Moderate Risk', AppColors.warning);
      } else {
        return RatioStatus('High Risk', AppColors.error);
      }
    }
  }
}

class RatioStatus {
  const RatioStatus(this.label, this.color);
  final String label;
  final Color color;
}