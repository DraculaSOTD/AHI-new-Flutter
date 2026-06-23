import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/profile_service.dart';
import '../services/health_assessment_orchestrator.dart';

/// Health Assessment Disclaimer Screen
///
/// Displays medical disclaimer and legal information before starting
/// the comprehensive health assessment. User must accept to proceed.
class HealthAssessmentDisclaimerScreen extends StatefulWidget {
  const HealthAssessmentDisclaimerScreen({super.key});

  @override
  State<HealthAssessmentDisclaimerScreen> createState() =>
      _HealthAssessmentDisclaimerScreenState();
}

class _HealthAssessmentDisclaimerScreenState
    extends State<HealthAssessmentDisclaimerScreen> {
  bool _acceptedMedicalDisclaimer = false;
  bool _acceptedAgeRequirement = false;
  bool _acceptedTerms = false;

  bool get _canProceed =>
      _acceptedMedicalDisclaimer && _acceptedAgeRequirement && _acceptedTerms;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Health Assessment',
          style: AppTypography.headlineSmall,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'Before We Begin',
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.primaryPurple,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingSmall),
                    Text(
                      'Please review and accept the following information to continue with your health assessment.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXLarge),

                    // Medical Disclaimer
                    _buildDisclaimerCard(
                      title: 'For Informational Use Only',
                      icon: Icons.medical_information_outlined,
                      iconColor: AppColors.error,
                      content: _medicalDisclaimerText,
                    ),
                    const SizedBox(height: AppDimensions.spacingLarge),

                    // Scan Disclaimer
                    _buildDisclaimerCard(
                      title: 'Scan Disclaimer',
                      icon: Icons.health_and_safety_outlined,
                      iconColor: AppColors.warning,
                      content: _scanDisclaimerText,
                    ),
                    const SizedBox(height: AppDimensions.spacingLarge),

                    // Privacy Notice
                    _buildDisclaimerCard(
                      title: 'Privacy & Data Collection',
                      icon: Icons.privacy_tip_outlined,
                      iconColor: AppColors.info,
                      content: _privacyNoticeText,
                    ),
                    const SizedBox(height: AppDimensions.spacingXLarge),

                    // Assessment Overview
                    Text(
                      'Assessment Overview',
                      style: AppTypography.headlineSmall,
                    ),
                    const SizedBox(height: AppDimensions.spacingMedium),
                    _buildAssessmentStep('1', 'Mental Health Surveys',
                        'Anxiety (GAD-7) and Depression (PHQ-9) questionnaires'),
                    _buildAssessmentStep('2', 'Vital Signs Monitoring',
                        'Three face scans with breaks for accurate heart rate, blood pressure, and more'),
                    _buildAssessmentStep('3', 'Body Measurements',
                        'Full body scan for composition analysis (optional)'),
                    _buildAssessmentStep('4', 'Fitness Assessment',
                        '3-minute step test to measure cardio fitness (if safe)'),
                    const SizedBox(height: AppDimensions.spacingMedium),
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.schedule, color: AppColors.secondaryBlue),
                          const SizedBox(width: AppDimensions.spacingSmall),
                          Expanded(
                            child: Text(
                              'Estimated time: 30-40 minutes',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.secondaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXLarge),

                    // Consent Checkboxes
                    Text(
                      'Required Consent',
                      style: AppTypography.headlineSmall,
                    ),
                    const SizedBox(height: AppDimensions.spacingMedium),

                    _buildCheckbox(
                      value: _acceptedMedicalDisclaimer,
                      onChanged: (value) => setState(() {
                        _acceptedMedicalDisclaimer = value ?? false;
                      }),
                      label:
                          'I understand this is for informational purposes only and is not a substitute for professional medical advice.',
                    ),
                    const SizedBox(height: AppDimensions.spacingMedium),

                    _buildCheckbox(
                      value: _acceptedAgeRequirement,
                      onChanged: (value) => setState(() {
                        _acceptedAgeRequirement = value ?? false;
                      }),
                      label: 'I confirm that I am 18 years of age or older.',
                    ),
                    const SizedBox(height: AppDimensions.spacingMedium),

                    _buildCheckbox(
                      value: _acceptedTerms,
                      onChanged: (value) => setState(() {
                        _acceptedTerms = value ?? false;
                      }),
                      label:
                          'I consent to data collection and processing for health assessment purposes.',
                    ),
                    const SizedBox(height: AppDimensions.spacingXLarge),
                  ],
                ),
              ),
            ),

            // Bottom Action Buttons
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: AppDimensions.buttonHeight,
                      child: ElevatedButton(
                        onPressed: _canProceed ? _acceptAndContinue : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPurple,
                          disabledBackgroundColor: AppColors.textSecondary.withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                          ),
                        ),
                        child: Text(
                          'I Agree - Start Assessment',
                          style: AppTypography.buttonLarge.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingSmall),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text(
                        'Cancel',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisclaimerCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: iconColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: AppDimensions.spacingMedium),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.headlineSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMedium),
          Text(
            content,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentStep(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingMedium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                number,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primaryPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String label,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primaryPurple,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingSmall),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptAndContinue() async {
    final orchestrator = context.read<HealthAssessmentOrchestrator>();

    // The orchestrator's persistence methods (saveAnxietySurvey,
    // saveFaceScanMeasurement, etc.) early-return when _currentAssessment is
    // null. Without this initialization step every save downstream is a silent
    // no-op, which is what was stranding the user on the first face scan in
    // the 3-scan assessment.
    final profileId = ProfileService().selectedProfile?.id;
    if (profileId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Select a profile before starting an assessment.',
          ),
        ),
      );
      return;
    }
    await orchestrator.startNewAssessment(profileId);
    await orchestrator.acceptDisclaimer();

    if (!mounted) return;

    // Navigate to first survey (Anxiety) - using push to maintain back stack
    context.push('/health-assessment/anxiety');
  }

  static const String _medicalDisclaimerText = '''
AHI Digital Health Assessment products and scans is not a substitute for the clinical judgment of a healthcare professional. AHI Digital Health Assessment products and scans are intended to improve your awareness and general wellness. AHI Digital Health Assessment products and scans do not diagnose, treat, mitigate, or prevent any disease, symptom, disorder or abnormal physical state. Consult with a healthcare professional or emergency services if you believe you may have a medical issue.''';

  static const String _scanDisclaimerText = '''
Results of scans are for wellness purposes only and are not intended to be used for clinical diagnosis, treatment, or any other medical purposes.

Scanning is available for users aged 18+.

All measurements are estimates and should not be used for medical decision-making.''';

  static const String _privacyNoticeText = '''
We use the camera to scan your face and body, collecting small data packets for calculating health metrics. Your images are processed locally on your device and are not stored, transmitted, or shared with third parties.

Health survey responses are stored locally on your device and may be aggregated anonymously for research purposes with your consent.''';
}
