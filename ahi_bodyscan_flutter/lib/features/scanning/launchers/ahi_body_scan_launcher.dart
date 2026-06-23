import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/services/logging_service.dart';
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
    LoggingService.info('launch start',
        tag: 'AHIBodyScanLauncher',
        context: {'isPartOfAssessment': isPartOfAssessment});

    // Check platform - Body scan is Android-only for now
    if (Platform.isIOS) {
      LoggingService.warning('Body scan called on iOS — unsupported',
          tag: 'AHIBodyScanLauncher');
      _showPlatformNotSupportedDialog(context);
      return;
    }

    final profileService = ProfileService();

    if (!profileService.hasSelectedProfile) {
      LoggingService.warning('No profile selected — aborting body scan',
          tag: 'AHIBodyScanLauncher');
      _showNoProfileDialog(context, 'Body Scan');
      return;
    }

    StreamSubscription<void>? heartbeat;
    final overallStopwatch = Stopwatch()..start();

    try {
      // Ask the OEM to exempt us from battery optimization before we start.
      // On Xiaomi/Redmi/Oppo/Vivo this is what stops the system killing the
      // native BodyScanResultsWorker mid-scan. Non-blocking — we proceed no
      // matter what the user decides; the timeout + retry/skip remains the net.
      await _requestBatteryExemption();

      LoggingService.info('Showing loading dialog',
          tag: 'AHIBodyScanLauncher');
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
      LoggingService.info(
        'Profile resolved',
        tag: 'AHIBodyScanLauncher',
        context: {
          'name': selectedProfile.name,
          'sex': selectedProfile.biologicalSex,
          'heightCm': selectedProfile.heightInCm,
          'weightKg': selectedProfile.weightInKg,
        },
      );

      // Convert profile data to AHI SDK format
      final scanOptions = {
        'enum_ent_sex': selectedProfile.biologicalSex == 'male' ? 'male' : 'female',
        'cm_ent_height': selectedProfile.heightInCm,
        'kg_ent_weight': selectedProfile.weightInKg,
        'debug_isDebug': false,
      };

      LoggingService.info('Calling AHITurnkey.initiateBodyScan',
          tag: 'AHIBodyScanLauncher', context: scanOptions);

      // Heartbeat: emit a warning every 10s while we're awaiting the SDK so a
      // hang is visible in the diagnostic log as a steady drumbeat.
      final sdkStopwatch = Stopwatch()..start();
      heartbeat = Stream.periodic(const Duration(seconds: 10))
          .listen((_) {
        LoggingService.warning(
          'Still awaiting initiateBodyScan',
          tag: 'AHIBodyScanLauncher',
          context: {'elapsedMs': sdkStopwatch.elapsedMilliseconds},
        );
      });

      // Launch native body scan with a 120s safety timeout. If the SDK never
      // returns, the timeout throws and we land in the catch block which
      // surfaces the retry/skip dialog with MIUI guidance. 120s (up from 90s)
      // gives slower mid-range devices headroom before the net fires.
      const bodyScanTimeout = Duration(seconds: 120);
      final results = await AHITurnkey.instance
          .initiateBodyScan(scanOptions)
          .timeout(bodyScanTimeout, onTimeout: () {
        throw TimeoutException(
          'AHI body scan did not return after ${bodyScanTimeout.inSeconds}s '
          '— the OS may have killed the AHI BodyScanResultsWorker.',
          bodyScanTimeout,
        );
      });

      await heartbeat.cancel();
      heartbeat = null;
      sdkStopwatch.stop();

      LoggingService.success(
        'initiateBodyScan returned',
        tag: 'AHIBodyScanLauncher',
        context: {
          'elapsedMs': sdkStopwatch.elapsedMilliseconds,
          'resultKeys': results.keys.toList(),
        },
      );

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

        LoggingService.info('Parsing BodyScanResult',
            tag: 'AHIBodyScanLauncher');
        // Convert Map results to typed BodyScanResult
        final bodyScanResult = BodyScanResult.fromJson(results, inputs);
        final usable = _isUsableBodyScanResult(bodyScanResult);
        LoggingService.info(
          'Parsed BodyScanResult',
          tag: 'AHIBodyScanLauncher',
          context: {
            'usable': usable,
            'chest': bodyScanResult.chestInCm,
            'waist': bodyScanResult.waistInCm,
            'hips': bodyScanResult.hipsInCm,
            'thigh': bodyScanResult.thighInCm,
            'inseam': bodyScanResult.inseamInCm,
            'bodyFat': bodyScanResult.bodyfatInPercent,
            'weightPredict': bodyScanResult.weightPredictInKg,
          },
        );

        if (!usable) {
          // Treat empty/zero-measurement results as a SDK failure. On
          // Xiaomi/MIUI (Redmi etc.) this is usually MIUI background-killing
          // the AHI BodyScanResultsWorker before it can produce measurements.
          // Throwing routes us into the existing catch -> retry/skip dialog.
          throw Exception(
            'Body scan returned empty/zero measurements. On Xiaomi/Redmi or '
            'Oppo/Vivo this is usually caused by the OS killing the AHI '
            'background worker.',
          );
        }

        if (isPartOfAssessment) {
          LoggingService.info('Saving body scan to orchestrator (assessment)',
              tag: 'AHIBodyScanLauncher');
          // Save results to health assessment orchestrator
          final orchestrator = context.read<HealthAssessmentOrchestrator>();

          // Pass full body scan result to orchestrator. saveBodyScan advances
          // the assessment step internally; we read the new currentStep below
          // to route into the next part of the flow (step test or summary).
          await orchestrator.saveBodyScan(bodyScanResult);
          LoggingService.success('Orchestrator save complete',
              tag: 'AHIBodyScanLauncher',
              context: {'nextStep': orchestrator.currentStep.toString()});

          // Dismiss the imperative AlertDialog only (root navigator hosts
          // showDialog's modal route). The route stack itself is GoRouter's
          // job — router.go(...) below replaces the location with the next
          // assessment step. Popping the screen below the dialog imperatively
          // here left go_router in an inconsistent state and the user saw a
          // black screen mid-transition.
          if (context.mounted && Navigator.canPop(context)) {
            LoggingService.info('Dismissing loading dialog',
                tag: 'AHIBodyScanLauncher');
            Navigator.of(context, rootNavigator: true).pop();
          }

          if (!context.mounted) return;
          LoggingService.info('Routing to next step',
              tag: 'AHIBodyScanLauncher',
              context: {'currentStep': orchestrator.currentStep.toString()});
          _routeAfterBodyScanStep(GoRouter.of(context), orchestrator);
        } else {
          // Dismiss the loading dialog from the root navigator only.
          if (context.mounted && Navigator.canPop(context)) {
            LoggingService.info(
                'Dismissing loading dialog (standalone)',
                tag: 'AHIBodyScanLauncher');
            Navigator.of(context, rootNavigator: true).pop();
          }

          // Standalone scan - Navigate to results screen with typed result
          if (context.mounted) {
            LoggingService.info('Pushing standalone results screen',
                tag: 'AHIBodyScanLauncher');
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

    } catch (e, st) {
      await heartbeat?.cancel();
      heartbeat = null;
      LoggingService.error(
        'Body scan launcher caught exception',
        tag: 'AHIBodyScanLauncher',
        error: e,
        context: {
          'errorType': e.runtimeType.toString(),
          'totalElapsedMs': overallStopwatch.elapsedMilliseconds,
          'stack': st.toString().split('\n').take(8).join(' | '),
        },
      );

      // Capture stable references BEFORE any await — BodyScanScreen's
      // BuildContext may unmount while the SDK Activity is running, after
      // which `context.mounted` is false and `context.go(...)` silently
      // no-ops. The GoRouter and the orchestrator both outlive the screen.
      HealthAssessmentOrchestrator? orchestrator;
      GoRouter? router;
      if (context.mounted) {
        orchestrator = context.read<HealthAssessmentOrchestrator>();
        router = GoRouter.of(context);
      }

      if (context.mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (e.toString().contains('USER_CANCELLED')) {
        // User cancelled, don't show error
        LoggingService.info('User cancelled body scan',
            tag: 'AHIBodyScanLauncher');
        return;
      }

      if (isPartOfAssessment && orchestrator != null && router != null) {
        // Assessment mode: don't strand the user. Offer to retry or to skip
        // the body scan so the rest of the assessment can complete.
        LoggingService.warning(
            'Body scan failed in assessment, prompting retry/skip',
            tag: 'AHIBodyScanLauncher');
        final choice = await showDialog<String>(
          context: context,
          useRootNavigator: true, // anchor to root navigator so it survives
          barrierDismissible: false,
          builder: (dialogCtx) => AlertDialog(
            title: const Text("Body scan didn't complete"),
            content: SingleChildScrollView(
              child: Text(
                "We couldn't process the body scan this time.\n\n"
                "$e\n\n"
                "If you're on Xiaomi / Redmi / Oppo / Vivo, the OS may have "
                "killed the scan worker. Open Settings → Apps → AHI "
                "BodyScan → Battery, set the background restriction to "
                "'No restrictions' or 'Allow background activity', then try "
                "again.",
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, 'skip'),
                child: const Text('Skip body scan'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogCtx, 'retry'),
                child: const Text('Try again'),
              ),
            ],
          ),
        );

        LoggingService.info('User chose dialog action',
            tag: 'AHIBodyScanLauncher', context: {'choice': choice ?? 'null'});

        if (choice == 'retry') {
          // Relaunch via the root navigator's currentContext, which is far
          // more durable than the (possibly-unmounted) BodyScanScreen one.
          final rootCtx =
              router.routerDelegate.navigatorKey.currentContext;
          if (rootCtx != null) {
            await AHIBodyScanLauncher.launch(rootCtx,
                isPartOfAssessment: true);
          }
          return;
        }

        // Skip path — drive everything through the captured references so a
        // detached BodyScanScreen context can't strand us.
        LoggingService.info('Skip path — advancing orchestrator past bodyScan',
            tag: 'AHIBodyScanLauncher');
        await orchestrator.skipBodyScan();
        _routeAfterBodyScanStep(router, orchestrator);
        return;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Body scan failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Ensure the heartbeat is always cancelled. It is cancelled in both the
      // success path and catch, but guard here too in case of an early throw
      // before either ran. (Screen keep-awake is handled app-wide in main.dart,
      // so there's no per-scan wakelock to release here.)
      await heartbeat?.cancel();
    }
  }

  /// Best-effort battery-optimization exemption request (Android only).
  /// Swallows any error — this is a reliability nudge, never a hard gate.
  static Future<void> _requestBatteryExemption() async {
    if (!Platform.isAndroid) return;
    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      if (!status.isGranted) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    } catch (e) {
      LoggingService.warning('Battery-optimization request failed',
          tag: 'AHIBodyScanLauncher', context: {'error': e.toString()});
    }
  }


  /// Validate that the AHI SDK actually produced measurements. On
  /// Xiaomi/MIUI we sometimes see all-null/zero output because MIUI killed
  /// the `BodyScanResultsWorker` background job before it could compute.
  /// If every key measurement is missing or non-positive, we route the
  /// failure into the catch path so the user gets the retry/skip dialog
  /// instead of silently advancing with empty data.
  static bool _isUsableBodyScanResult(BodyScanResult r) {
    final values = <double?>[
      r.chestInCm,
      r.waistInCm,
      r.hipsInCm,
      r.thighInCm,
      r.inseamInCm,
      r.bodyfatInPercent,
      r.weightPredictInKg,
    ];
    return values.any((v) => v != null && v > 0);
  }

  /// Route forward after the orchestrator has been advanced past the
  /// `bodyScan` step. Used by both the success path and the skip-on-error
  /// path so they can't drift. Takes a [GoRouter] rather than a
  /// [BuildContext] so the caller doesn't need a mounted screen context.
  static void _routeAfterBodyScanStep(
    GoRouter router,
    HealthAssessmentOrchestrator orchestrator,
  ) {
    final nextStep = orchestrator.currentStep;
    switch (nextStep) {
      case AssessmentStep.stepTestPrep:
        router.go('/health-assessment/step-test-prep');
        break;
      case AssessmentStep.summary:
      default:
        router.go('/health-assessment/summary');
        break;
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