//
//  AHI Turnkey Body Scan Launcher
//
//  Copyright (c) AHI. All rights reserved.
//

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../src/ahi_sdk_turnkey.dart';
import '../models/ahi_user_data.dart';
import '../ahi_turnkey_widgets/ahi_input_sheet_widget.dart';
import '../ahi_turnkey_widgets/measurement/ahi_expandable_measurement.dart';
import '../ahi_turnkey_widgets/guide/tk_body_scan_guide_page.dart';
import '../ahi_turnkey_widgets/native/tk_native_scanning_page.dart';
import '../ahi_turnkey_widgets/processing/tk_body_scan_processing_page.dart';
import '../ahi_turnkey_widgets/results/tk_body_scan_results_page.dart';
import '../ahi_turnkey_widgets/download/tk_download_assets_page.dart';
import '../ahi_turnkey_widgets/bha/tk_bha_survey_page.dart';
import '../ahi_turnkey_widgets/bha/tk_bha_results_page.dart';
import '../ahi_turnkey_services/ahi_bha_service.dart';
import '../ahi_turnkey_models/bha/ahi_bha_model.dart';
import '../../../services/profile_service.dart';
import '../extensions/context_ahi.dart';

class TkBodyScanLauncher {
  TkBodyScanLauncher({
    this.exitPressed,
  }) {
    resultsPageBuilder =
        (TkBodyScanResultData data) => TkBodyScanResultsPage(
          results: data,
          onClose: () {},
        );
  }
  final void Function()? exitPressed;
  late Widget Function(TkBodyScanResultData data) resultsPageBuilder;

  void launch(BuildContext context) {
    final ProfileService profileService = ProfileService();
    
    if (!profileService.hasSelectedProfile) {
      _showNoProfileDialog(context, 'Body Scan');
      return;
    }

    final selectedProfile = profileService.selectedProfile!;
    final TkUserDataMutable healthDataMutable = TkUserDataMutable(
      biologicalSex: selectedProfile.biologicalSex == 'male' 
          ? TkBiologicalSex.BS_MALE 
          : TkBiologicalSex.BS_FEMALE,
      heightInCm: selectedProfile.heightInCm,
      weightInKg: selectedProfile.weightInKg,
      age: selectedProfile.ageInYears,
      ethnicityType: TkEthnicityType.WHITE, // Default, could be made configurable
    );

    // Skip input sheet since we have profile data - directly validate and launch
    if (healthDataMutable.isValidData()) {
      // Check if resources are available
      _checkResourcesAndLaunchScan(context, healthDataMutable);
    } else {
      // Show error if profile data is invalid
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile data is incomplete. Please update your profile.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _checkResourcesAndLaunchScan(BuildContext context, TkUserDataMutable healthData) async {
    try {
      final bool resourcesAvailable = await AHITurnkey.instance.areResourcesAvailable();
      
      if (!resourcesAvailable) {
        Navigator.push(
          context,
          MaterialPageRoute<dynamic>(
            builder: (BuildContext downloadPageContext) => TkDownloadAssetsPage(
              onContinueTapped: () {
                Navigator.pop(context);
                _launchScan(context, healthData);
              },
            ),
          ),
        );
      } else {
        _launchScan(context, healthData);
      }
    } catch (e) {
      // If resource check fails, continue with scan attempt
      _launchScan(context, healthData);
    }
  }

  void _launchScan(BuildContext scanPageContext, TkUserDataMutable healthData) {
    // Get profile health data
    final ProfileService profileService = ProfileService();
    final selectedProfile = profileService.selectedProfile;

    // Convert profile health data to SDK format
    bool isSmoker = false;
    bool hasHypertension = false;
    String diabetesStatus = 'non_diabetic';

    if (selectedProfile != null) {
      // Convert smoking status: 'current' -> true, 'former'/'never' -> false
      isSmoker = selectedProfile.smokingStatus.toLowerCase() == 'current';

      // Convert hypertension: 'yes' -> true, 'no' -> false
      hasHypertension = selectedProfile.hasHypertension.toLowerCase() == 'yes';

      // Convert diabetes status
      switch (selectedProfile.diabetesStatus.toLowerCase()) {
        case 'type_1':
        case 'type1':
          diabetesStatus = 'type_1';
          break;
        case 'type_2':
        case 'type2':
          diabetesStatus = 'type_2';
          break;
        case 'prediabetic':
        case 'pre-diabetic':
          diabetesStatus = 'prediabetic';
          break;
        default:
          diabetesStatus = 'non_diabetic';
      }
    }

    Navigator.push(
      scanPageContext,
      MaterialPageRoute<dynamic>(
        builder: (BuildContext guidePageContext) => TkBodyScanGuidePage(
          userData: healthData.toImmutable(),
          onStartScan: () {
            final inputs = TkBodyScanInputs.fromHealthData(
              healthData,
              isSmoker: isSmoker,
              hasHypertension: hasHypertension,
              diabetesStatus: diabetesStatus,
            );
            Navigator.pushReplacement(
              guidePageContext,
              MaterialPageRoute<dynamic>(
                builder: (nativeScanContext) => TkNativeScanningPage(
                  scanType: TkScanType.body,
                  scanOptions: inputs.asOptionsMap(debug: false),
                  onScanComplete: (scanData) async {
                    await _handleScanResults(nativeScanContext, scanData, inputs);
                  },
                  onScanError: (error) {
                    ScaffoldMessenger.of(nativeScanContext).showSnackBar(
                      SnackBar(
                        content: Text('Scan failed: $error'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    Navigator.of(nativeScanContext).pop();
                    exitPressed?.call();
                  },
                  onCancel: () {
                    Navigator.of(guidePageContext).pop();
                    exitPressed?.call();
                  },
                ),
              ),
            );
          },
          onCancel: () {
            Navigator.of(scanPageContext).pop();
            exitPressed?.call();
          },
        ),
      ),
    );
  }

  Future<void> _handleScanResults(
    BuildContext context,
    Map<String, dynamic> json,
    TkBodyScanInputs inputs,
  ) async {
    final TkBodyScanResultData result = TkBodyScanResultData(
        json: json, scanDate: DateTime.now(), inputs: inputs);
    
    // Store result locally if needed
    // TODO: Integrate with local storage
    
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<dynamic>(
          builder: (resultsContext) => TkBodyScanResultsPage(
            results: result,
            onClose: () {
              Navigator.of(resultsContext).pop();
              exitPressed?.call();
            },
            onSaveResults: (resultData) {
              // TODO: Implement save functionality
              ScaffoldMessenger.of(resultsContext).showSnackBar(
                const SnackBar(content: Text('Results saved successfully!')),
              );
            },
            onHealthAssessment: () {
              _launchBHAFlow(resultsContext, result);
            },
          ),
        ),
      );
    }
  }

  /// Launch BHA (Biological Health Assessment) flow
  void _launchBHAFlow(BuildContext context, TkBodyScanResultData scanResults) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Complete Health Assessment'),
        content: const Text(
          'Would you like to complete a brief health survey to get a comprehensive health assessment based on your scan results?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Maybe Later'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _startBHASurvey(context, scanResults);
            },
            child: const Text('Get Assessment'),
          ),
        ],
      ),
    );
  }

  /// Start BHA survey flow
  void _startBHASurvey(BuildContext context, TkBodyScanResultData scanResults) {
    Navigator.push(
      context,
      MaterialPageRoute<dynamic>(
        builder: (surveyContext) => TkBHASurveyPage(
          onSurveyCompleted: (surveyResponses) {
            Navigator.pop(surveyContext);
            _generateBHAProfile(context, scanResults, surveyResponses);
          },
          onSkip: () {
            Navigator.pop(surveyContext);
            _generateBHAProfile(context, scanResults, null);
          },
        ),
      ),
    );
  }

  /// Generate BHA profile and show results
  void _generateBHAProfile(
    BuildContext context, 
    TkBodyScanResultData scanResults, 
    List<BHASurveyResponse>? surveyResponses,
  ) async {
    // Show loading indicator
    context.showProcessing();

    try {
      final ProfileService profileService = ProfileService();
      final selectedProfile = profileService.selectedProfile;
      
      if (selectedProfile == null) {
        context.hideProcessing();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile not found for health assessment')),
        );
        return;
      }

      // Convert profile to user data
      final userData = TkUserData(
        biologicalSex: selectedProfile.biologicalSex == 'male' 
            ? TkBiologicalSex.BS_MALE 
            : TkBiologicalSex.BS_FEMALE,
        heightInCm: selectedProfile.heightInCm,
        weightInKg: selectedProfile.weightInKg,
        age: selectedProfile.age,
        ethnicityType: TkEthnicityType.WHITE,
      );

      // Generate BHA profile
      final bhaProfile = await AHIBHAService().generateBHAProfile(
        userId: selectedProfile.id,
        userData: userData,
        bodyScanResults: scanResults.json,
        surveyResponses: surveyResponses,
      );

      context.hideProcessing();

      // Show BHA results
      Navigator.push(
        context,
        MaterialPageRoute<dynamic>(
          builder: (bhaResultsContext) => TkBHAResultsPage(
            bhaProfile: bhaProfile,
            onClose: () {
              Navigator.of(bhaResultsContext).pop();
            },
            onShareResults: () {
              _shareBHAResults(bhaResultsContext, bhaProfile);
            },
            onViewRecommendations: () {
              _showAllRecommendations(bhaResultsContext, bhaProfile);
            },
          ),
        ),
      );

    } catch (e) {
      context.hideProcessing();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate health assessment: $e')),
      );
    }
  }

  /// Share BHA results
  void _shareBHAResults(BuildContext context, BHAProfile bhaProfile) {
    // TODO: Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing feature coming soon!')),
    );
  }

  /// Show all recommendations in a detailed view
  void _showAllRecommendations(BuildContext context, BHAProfile bhaProfile) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('All Recommendations'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: bhaProfile.recommendations.map((recommendation) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 8, right: 12),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          recommendation,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void showInputSheet(
    BuildContext context,
    TkUserDataMutable healthData,
    void Function() startScan,
  ) {
    TkInputSheet(
      title: 'Confirm Weight',
      message: 'Please confirm your current weight for accurate body measurements.',
      buttonText: 'Continue',
      inputLabel: 'Weight',
      inputWidget: TkMeasurementExpandable(
        model: healthData,
        measurementType: TkMeasurementType.weight,
      ),
      onPressed: () {
        startScan();
      },
    ).show(context);
  }

  void _showNoProfileDialog(BuildContext context, String scanType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Profile Required'),
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
}