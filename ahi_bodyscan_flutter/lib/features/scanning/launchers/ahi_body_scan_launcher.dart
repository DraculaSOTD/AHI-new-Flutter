import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../src/ahi_sdk_turnkey.dart';
import '../../../services/profile_service.dart';
import '../../../services/ahi_scanner/models/scan_inputs.dart';
import '../../../services/ahi_scanner/models/scan_results.dart';
import '../../../services/ahi_scanner/models/scan_enums.dart';
import '../../health_assessment/services/health_assessment_orchestrator.dart';
import '../results/body_scan_results_screen.dart';

/// Native AHI Body Scan Launcher
class AHIBodyScanLauncher {
  /// Launch native body scan using AHI SDK
  ///
  /// [context] - Build context for navigation and state access
  /// [isPartOfAssessment] - If true, saves results to orchestrator and navigates to summary
  ///                        If false, displays results screen (standalone scan)
  static Future<void> launch(
    BuildContext context, {
    bool isPartOfAssessment = false,
  }) async {
    // Check platform - Body scan is Android-only for now
    if (Platform.isIOS) {
      _showPlatformNotSupportedDialog(context);
      return;
    }

    final profileService = ProfileService();

    if (!profileService.hasSelectedProfile) {
      _showNoProfileDialog(context, 'Body Scan');
      return;
    }

    try {
      // Show loading dialog
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Preparing body scan...'),
              ],
            ),
          ),
        );
      }

      final selectedProfile = profileService.selectedProfile!;
      
      // Convert profile data to AHI SDK format
      final scanOptions = {
        'enum_ent_sex': selectedProfile.biologicalSex == 'male' ? 'male' : 'female',
        'cm_ent_height': selectedProfile.heightInCm,
        'kg_ent_weight': selectedProfile.weightInKg,
        'debug_isDebug': false,
      };

      // Launch native body scan (loading dialog stays visible)
      final results = await AHITurnkey.instance.initiateBodyScan(scanOptions);

      if (context.mounted) {
        // Create BodyScanInputs from profile for result typing
        final biologicalSex = selectedProfile.biologicalSex == 'male'
            ? BiologicalSex.male
            : BiologicalSex.female;

        final inputs = BodyScanInputs.fromUserData(
          sex: biologicalSex,
          heightInCm: selectedProfile.heightInCm,
          weightInKg: selectedProfile.weightInKg,
          ageInYears: selectedProfile.ageInYears,
        );

        // Convert Map results to typed BodyScanResult
        final bodyScanResult = BodyScanResult.fromJson(results, inputs);

        if (isPartOfAssessment) {
          // Save results to health assessment orchestrator
          final orchestrator = context.read<HealthAssessmentOrchestrator>();

          // Pass full body scan result to orchestrator
          await orchestrator.saveBodyScan(bodyScanResult);

          // Dismiss loading dialog before navigation
          if (context.mounted && Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }

          // Navigate to health assessment summary
          if (context.mounted) {
            // Pop the body scan camera screen from the navigation stack
            // to prevent returning to it after completing the assessment
            Navigator.of(context).pop();
            context.go('/health-assessment/summary');
          }
        } else {
          // Dismiss loading dialog before navigation
          if (context.mounted && Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }

          // Standalone scan - Navigate to results screen with typed result
          if (context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => BodyScanResultsScreen(
                  result: bodyScanResult,
                ),
              ),
            );
          }
        }
      }

    } catch (e) {
      // Dismiss loading dialog if still showing
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      if (context.mounted) {
        if (e.toString().contains('USER_CANCELLED')) {
          // User cancelled, don't show error
          return;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Body scan failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static void _showNoProfileDialog(BuildContext context, String scanType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile Required'),
        content: Text('Please create and select a profile before starting $scanType.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static void _showPlatformNotSupportedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Android Only'),
        content: const Text(
          'Body Scan is currently only available on Android devices. '
          'iOS support will be added in a future update.\n\n'
          'You can skip this step and continue with the health assessment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}