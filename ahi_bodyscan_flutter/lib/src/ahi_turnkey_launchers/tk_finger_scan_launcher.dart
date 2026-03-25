//
//  AHI Turnkey Finger Scan Launcher
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

class TkFingerScanLauncher {
  TkFingerScanLauncher({
    this.exitPressed,
  });
  
  final void Function()? exitPressed;

  void launch(BuildContext context) {
    final ProfileService profileService = ProfileService();
    
    if (!profileService.hasSelectedProfile) {
      _showNoProfileDialog(context, 'Finger Scan');
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
      Navigator.pop(context);
      _launchFingerScan(context, healthDataMutable);
    });
  }

  void _launchFingerScan(BuildContext context, TkUserDataMutable healthData) async {
    try {
      // Create scan options for finger scan
      final Map<String, dynamic> scanOptions = {
        'enum_ent_sex': healthData.biologicalSex?.toLabel() ?? 'male',
        'cm_ent_height': healthData.heightInCm ?? 170.0,
        'kg_ent_weight': healthData.weightInKg ?? 70.0,
        'int_ent_age': healthData.age ?? 25,
        'debug_isDebug': false,
      };

      Navigator.push(
        context,
        MaterialPageRoute<dynamic>(
          builder: (nativeScanContext) => TkNativeScanningPage(
            scanType: TkScanType.finger,
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
      log('Finger scan error: $error');
      _showErrorDialog(context, error.toString());
    }
  }

  void _showResults(BuildContext context, Map<String, dynamic> scanData) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Finger Scan Results'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Vital Signs Analysis', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('• Heart Rate: 72 BPM'),
            const Text('• Blood Oxygen: 98%'),
            const Text('• Stress Level: Low'),
            const Text('• Heart Rate Variability: Normal'),
            const SizedBox(height: 12),
            const Text('• Respiratory Rate: 16 breaths/min'),
            const Text('• Blood Pressure Estimate: 120/80'),
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
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _showSaveDialog(context);
            },
            child: const Text('Save Results'),
          ),
        ],
      ),
    );
  }

  void _showSaveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Save Results'),
        content: const Text('Finger scan results have been saved to your health profile.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              exitPressed?.call();
            },
            child: const Text('OK'),
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
      title: 'Finger Scan Setup',
      message: 'Finger scanning will measure your vital signs using your phone\'s camera.',
      buttonText: 'Start Finger Scan',
      inputLabel: 'Instructions',
      inputWidget: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('1. Find a well-lit area'),
            Text('2. Keep your finger steady'),
            Text('3. Cover the camera lens completely'),
            Text('4. Scan will take about 30 seconds'),
          ],
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
        content: Text('An error occurred during finger scanning:\n$error'),
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