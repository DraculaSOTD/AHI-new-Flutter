import '../../../core/services/logging_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';

class TermsOfServiceScreen extends StatefulWidget {
  const TermsOfServiceScreen({super.key});

  @override
  State<TermsOfServiceScreen> createState() => _TermsOfServiceScreenState();
}

class _TermsOfServiceScreenState extends State<TermsOfServiceScreen> {
  bool _acceptTerms = false;
  bool _acceptPrivacy = false;
  bool _isAccepting = false;
  bool _isDeclining = false;
  final ScrollController _scrollController = ScrollController();

  /// Safely save terms acceptance to SharedPreferences with retry logic
  /// Returns true if saved successfully, false otherwise
  Future<bool> _saveTermsAcceptance() async {
    const maxRetries = 3;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        LoggingService.info('Attempting to save terms acceptance', tag: 'TermsOfService', context: {'attempt': attempt, 'maxRetries': maxRetries});
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('termsAccepted', true);
        LoggingService.success('Terms acceptance saved successfully', tag: 'TermsOfService');
        return true;
      } catch (e) {
        LoggingService.warning('Failed to save terms acceptance', tag: 'TermsOfService', context: {'attempt': attempt, 'maxRetries': maxRetries, 'error': e.toString()});
        if (attempt < maxRetries) {
          await Future.delayed(Duration(milliseconds: 300 * attempt));
        }
      }
    }

    // If all retries failed, log warning but allow app to continue
    LoggingService.warning('SharedPreferences failed - continuing without persistence', tag: 'TermsOfService', context: {'maxRetries': maxRetries});
    LoggingService.warning('Terms acceptance will not persist across app restarts', tag: 'TermsOfService');
    return false;
  }

  /// Safely clear auth data from SharedPreferences with retry logic
  /// Returns true if cleared successfully, false otherwise
  Future<bool> _clearAuthData() async {
    const maxRetries = 3;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        LoggingService.info('Attempting to clear auth data', tag: 'TermsOfService', context: {'attempt': attempt, 'maxRetries': maxRetries});
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('isAuthenticated');
        await prefs.remove('userEmail');
        LoggingService.success('Auth data cleared successfully', tag: 'TermsOfService');
        return true;
      } catch (e) {
        LoggingService.warning('Failed to clear auth data', tag: 'TermsOfService', context: {'attempt': attempt, 'maxRetries': maxRetries, 'error': e.toString()});
        if (attempt < maxRetries) {
          await Future.delayed(Duration(milliseconds: 300 * attempt));
        }
      }
    }

    // If all retries failed, log warning but allow app to continue
    LoggingService.warning('SharedPreferences failed - continuing without clearing data', tag: 'TermsOfService', context: {'maxRetries': maxRetries});
    return false;
  }

  Future<void> _handleAccept() async {
    if (!_acceptTerms || !_acceptPrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept both terms to continue'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isAccepting = true;
    });

    try {
      // Save terms acceptance (with retry logic)
      await _saveTermsAcceptance();

      if (!mounted) return;

      // Navigate to home (even if SharedPreferences failed)
      context.go('/home');
    } catch (e) {
      LoggingService.error('Terms acceptance error', error: e, tag: 'TermsOfService');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save acceptance: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      // Always clear loading state
      if (mounted) {
        setState(() {
          _isAccepting = false;
        });
      }
    }
  }

  Future<void> _handleDecline() async {
    setState(() {
      _isDeclining = true;
    });

    try {
      // Clear auth data (with retry logic)
      await _clearAuthData();

      if (!mounted) return;

      // Navigate to login (even if SharedPreferences failed)
      context.go('/login');
    } catch (e) {
      LoggingService.error('Terms decline error', error: e, tag: 'TermsOfService');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      // Always clear loading state
      if (mounted) {
        setState(() {
          _isDeclining = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Terms of Service'),
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleDecline,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome to AHI BodyScan',
                            style: AppTypography.headingMedium.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Before you begin, please review and accept our terms of service and privacy policy.',
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Terms of Service',
                            style: AppTypography.headingSmall.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _termsText,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Privacy Policy',
                            style: AppTypography.headingSmall.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _privacyText,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Acceptance checkboxes
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                      child: Column(
                        children: [
                          CheckboxListTile(
                            value: _acceptTerms,
                            onChanged: (value) {
                              setState(() {
                                _acceptTerms = value ?? false;
                              });
                            },
                            title: Text(
                              'I accept the Terms of Service',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: AppColors.primaryPurple,
                          ),
                          CheckboxListTile(
                            value: _acceptPrivacy,
                            onChanged: (value) {
                              setState(() {
                                _acceptPrivacy = value ?? false;
                              });
                            },
                            title: Text(
                              'I accept the Privacy Policy',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: AppColors.primaryPurple,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom buttons
          Container(
            padding: EdgeInsets.only(
              left: AppDimensions.paddingLarge,
              right: AppDimensions.paddingLarge,
              top: AppDimensions.paddingLarge,
              bottom: AppDimensions.paddingLarge + MediaQuery.of(context).viewPadding.bottom,
            ),
            decoration: BoxDecoration(
              color: AppColors.backgroundWhite,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  offset: const Offset(0, -2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: AppDimensions.buttonHeightLarge,
                    child: OutlinedButton(
                      onPressed: (_isDeclining || _isAccepting) ? null : _handleDecline,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.borderLight,
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusPill,
                          ),
                        ),
                      ),
                      child: _isDeclining
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.textSecondary,
                                ),
                              ),
                            )
                          : Text(
                              'Decline',
                              style: AppTypography.buttonMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: AppDimensions.buttonHeightLarge,
                    child: ElevatedButton(
                      onPressed: (_isAccepting || _isDeclining || !_acceptTerms || !_acceptPrivacy)
                          ? null
                          : _handleAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        disabledBackgroundColor: AppColors.borderLight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusPill,
                          ),
                        ),
                      ),
                      child: _isAccepting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.textWhite,
                                ),
                              ),
                            )
                          : Text(
                              'Accept',
                              style: AppTypography.buttonMedium.copyWith(
                                color: AppColors.textWhite,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const String _termsText = '''
1. Acceptance of Terms
By using the AHI BodyScan application, you agree to be bound by these Terms of Service.

2. Use of Service
AHI BodyScan provides health and body measurement services using computer vision technology. The measurements and health insights provided are for informational purposes only and should not replace professional medical advice.

3. User Data
We collect and process body measurements, health metrics, and images as necessary to provide our services. All data is handled in accordance with our Privacy Policy.

4. Accuracy Disclaimer
While we strive for accuracy, body measurements and health metrics may vary. Results should be used as estimates and not for medical diagnosis.

5. User Responsibilities
- Provide accurate personal information
- Use the service responsibly
- Maintain the confidentiality of your account
- Follow proper scanning procedures for best results

6. Limitations of Liability
AHI BodyScan is not liable for any indirect, incidental, or consequential damages arising from the use of our service.

7. Modifications to Service
We reserve the right to modify or discontinue the service at any time with reasonable notice.

8. Governing Law
These terms are governed by applicable local laws and regulations.
''';

  static const String _privacyText = '''
1. Information We Collect
- Personal information (name, email, age, gender)
- Body measurements and health metrics
- Images captured during scanning sessions
- Device information and usage statistics

2. How We Use Your Information
- To provide body measurement and health analysis
- To improve our algorithms and services
- To personalize your experience
- To communicate service updates

3. Data Storage and Security
- All data is encrypted in transit and at rest
- Images are processed locally when possible
- We implement industry-standard security measures
- Data retention follows applicable regulations

4. Data Sharing
We do not sell your personal data. Information may be shared only:
- With your explicit consent
- To comply with legal obligations
- With service providers under strict confidentiality agreements

5. Your Rights
You have the right to:
- Access your personal data
- Request data correction or deletion
- Opt-out of certain data processing
- Export your data

6. Children's Privacy
Our service is not intended for users under 13 years of age.

7. Contact Us
For privacy concerns, please contact our support team through the app settings.
''';
}