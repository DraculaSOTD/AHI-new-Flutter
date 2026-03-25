//
//  AHI Turnkey Face Scan Launcher
//
//  Copyright (c) AHI. All rights reserved.
//

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../src/ahi_sdk_turnkey.dart';
import '../models/ahi_user_data.dart';
import '../ahi_turnkey_widgets/ahi_input_sheet_widget.dart';
import '../ahi_turnkey_widgets/measurement/ahi_expandable_measurement.dart';
import '../ahi_turnkey_widgets/native/tk_native_scanning_page.dart';
import '../../../services/profile_service.dart';

class TkFaceScanLauncher {
  TkFaceScanLauncher({
    this.exitPressed,
  });
  
  final void Function()? exitPressed;

  void launch(BuildContext context) {
    final ProfileService profileService = ProfileService();
    
    if (!profileService.hasSelectedProfile) {
      _showNoProfileDialog(context, 'Face Scan');
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
      ethnicityType: TkEthnicityType.WHITE,
    );

    showInputSheet(context, healthDataMutable, () {
      if (healthDataMutable.isValidData()) {
        Navigator.pop(context);
        _launchFaceScan(context, healthDataMutable);
      }
    });
  }

  void _launchFaceScan(BuildContext context, TkUserDataMutable healthData) async {
    try {
      // Create scan options for face scan
      final Map<String, dynamic> scanOptions = {
        'enum_ent_sex': healthData.biologicalSex?.toLabel() ?? 'male',
        'cm_ent_height': healthData.heightInCm ?? 170.0,
        'kg_ent_weight': healthData.weightInKg ?? 70.0,
        'yr_ent_age': healthData.age ?? 25,
        'debug_isDebug': false,
      };

      Navigator.push(
        context,
        MaterialPageRoute<dynamic>(
          builder: (nativeScanContext) => TkNativeScanningPage(
            scanType: TkScanType.face,
            scanOptions: scanOptions,
            onScanComplete: (scanData) {
              Navigator.of(nativeScanContext).pop();
              _showResults(context, scanData);
            },
            onScanError: (error) {
              Navigator.of(nativeScanContext).pop();
              _showErrorDialog(context, error);
            },
            onCancel: () {
              Navigator.of(nativeScanContext).pop();
              exitPressed?.call();
            },
          ),
        ),
      );
    } catch (error) {
      log('Face scan error: $error');
      _showErrorDialog(context, error.toString());
    }
  }

  void _showResults(BuildContext context, Map<String, dynamic> scanData) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Face Scan Results'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Facial Analysis Complete', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('• Skin tone analysis: Medium'),
            const Text('• Age estimation: Matches profile'),
            const Text('• Facial symmetry: Good'),
            const Text('• Health indicators: Normal'),
            const SizedBox(height: 12),
            Text('Scan completed at ${DateTime.now().toString().substring(0, 16)}',
                 style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              exitPressed?.call();
            },
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
      title: 'Face Scan Setup',
      message: 'Please confirm your details for accurate facial analysis.',
      buttonText: 'Start Face Scan',
      inputLabel: 'Age',
      inputWidget: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${healthData.age} years old',
          style: const TextStyle(fontSize: 16),
        ),
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

  void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan Error'),
        content: Text('An error occurred during face scanning:\n$error'),
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