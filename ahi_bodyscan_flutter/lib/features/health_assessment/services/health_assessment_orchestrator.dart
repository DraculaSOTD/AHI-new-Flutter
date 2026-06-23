import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/health_assessment.dart';
import '../models/anxiety_survey_result.dart';
import '../models/depression_survey_result.dart';
import '../models/fitness_test_result.dart';
import '../../../services/ahi_scanner/models/scan_results.dart';
import '../../../core/services/logging_service.dart';

/// Orchestrates the complete Health Assessment flow
///
/// This service manages the state and progression through all assessment steps:
/// 1. Disclaimer acceptance
/// 2. Anxiety Survey (GAD-7)
/// 3. Depression Survey (PHQ-9)
/// 4. Fitness Screening (PAR-Q)
/// 5. Step Test (if safe) or Skip
/// 6. Face Scan #1 (resting baseline)
/// 7. 60-second break
/// 8. Face Scan #2
/// 9. 60-second break
/// 10. Face Scan #3
/// 11. Body Scan (optional)
/// 12. Finger Scan (optional)
/// 13. Summary & Results
class HealthAssessmentOrchestrator extends ChangeNotifier {
  static const String _storageKey = 'current_health_assessment';
  HealthAssessment? _currentAssessment;
  AssessmentStep _currentStep = AssessmentStep.disclaimer;

  HealthAssessment? get currentAssessment => _currentAssessment;
  AssessmentStep get currentStep => _currentStep;
  bool get hasActiveAssessment => _currentAssessment != null;
  bool get isComplete => _currentAssessment?.isComplete ?? false;

  /// Assessment step enumeration
  /// Represents each stage in the health assessment flow
  final List<AssessmentStep> _completedSteps = [];

  /// Start a new health assessment
  Future<void> startNewAssessment(String profileId) async {
    final uuid = const Uuid();
    _currentAssessment = HealthAssessment(
      id: uuid.v4(),
      profileId: profileId,
      startedAt: DateTime.now(),
      currentStep: 0,
    );
    _currentStep = AssessmentStep.disclaimer;
    _completedSteps.clear();
    await _saveToStorage();
    notifyListeners();
    LoggingService.success('Started new assessment', tag: 'HealthAssessmentOrch', context: {'id': _currentAssessment!.id});
  }

  /// Resume an existing assessment from storage
  Future<bool> resumeAssessment() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null) {
        _currentAssessment = HealthAssessment.fromJsonString(jsonString);
        _currentStep = _getStepFromIndex(_currentAssessment!.currentStep);
        notifyListeners();
        LoggingService.success('Resumed assessment', tag: 'HealthAssessmentOrch', context: {'id': _currentAssessment!.id});
        return true;
      }
    } catch (e) {
      LoggingService.error('Error resuming assessment', error: e, tag: 'HealthAssessmentOrch');
    }
    return false;
  }

  /// Accept disclaimer and proceed to anxiety survey
  Future<void> acceptDisclaimer() async {
    if (_currentStep != AssessmentStep.disclaimer) return;
    await _advanceToNextStep();
  }

  /// Save anxiety survey results
  Future<void> saveAnxietySurvey(AnxietySurveyResult result) async {
    if (_currentAssessment == null) return;
    _currentAssessment = _currentAssessment!.copyWith(
      anxietySurvey: result,
    );
    await _advanceToNextStep();
  }

  /// Save depression survey results
  Future<void> saveDepressionSurvey(DepressionSurveyResult result) async {
    if (_currentAssessment == null) return;
    _currentAssessment = _currentAssessment!.copyWith(
      depressionSurvey: result,
    );

    // Check for critical mental health flags
    if (result.hasSelfHarmThoughts) {
      LoggingService.warning('CRITICAL: Self-harm thoughts detected', tag: 'HealthAssessmentOrch');
      // Crisis intervention will be handled at UI level
    }

    await _advanceToNextStep();
  }

  /// Save fitness screening results
  Future<void> saveFitnessScreening(FitnessTestResult result) async {
    if (_currentAssessment == null) return;
    _currentAssessment = _currentAssessment!.copyWith(
      fitnessTest: result,
    );

    // If not safe for exercise, skip step test
    if (!result.isSafeForExercise) {
      LoggingService.warning('User not safe for exercise, skipping step test', tag: 'HealthAssessmentOrch');
      // Skip step test prep and active test
      _completedSteps.add(AssessmentStep.stepTestPrep);
      _completedSteps.add(AssessmentStep.stepTestActive);
      _completedSteps.add(AssessmentStep.postExerciseFaceScan);
    }

    await _advanceToNextStep();
  }

  /// Save step test preparation (step height, etc.)
  Future<void> saveStepTestPreparation({
    required double stepHeightCm,
  }) async {
    if (_currentAssessment == null) return;

    // Update fitness test with step height
    final updatedFitnessTest = _currentAssessment!.fitnessTest?.copyWith(
      stepHeightCm: stepHeightCm,
    );

    _currentAssessment = _currentAssessment!.copyWith(
      fitnessTest: updatedFitnessTest,
    );

    await _advanceToNextStep();
  }

  /// Complete step test and save results
  Future<void> completeStepTest({
    required int restingHeartRate,
    required int postExerciseHeartRate,
  }) async {
    if (_currentAssessment == null) return;

    // Calculate fitness score and level
    final fitnessTest = _currentAssessment!.fitnessTest;
    if (fitnessTest != null) {
      final updatedFitnessTest = fitnessTest.copyWith(
        restingHeartRate: restingHeartRate,
        postExerciseHeartRate: postExerciseHeartRate,
        completedAt: DateTime.now(),
      );

      _currentAssessment = _currentAssessment!.copyWith(
        fitnessTest: updatedFitnessTest,
      );
    }

    await _advanceToNextStep();
  }

  /// Save the post-exercise face scan from the step-test cool-down. Its HR
  /// becomes `fitnessTest.postExerciseHeartRate` and we advance to summary —
  /// we explicitly do NOT append to `vitalSigns.measurements` because that
  /// would skew the resting-vitals average sent to Lambda.
  Future<void> savePostExerciseFaceScan(FaceScanMeasurement measurement) async {
    if (_currentAssessment == null) return;
    final fitness = _currentAssessment!.fitnessTest;
    final updatedFitness = fitness?.copyWith(
      postExerciseHeartRate: measurement.heartRate ?? 0,
      completedAt: DateTime.now(),
    );
    _currentAssessment = _currentAssessment!.copyWith(
      fitnessTest: updatedFitness,
      postExerciseFaceScan: measurement,
    );
    LoggingService.success(
      'Saved post-exercise face scan',
      tag: 'HealthAssessmentOrch',
      context: {
        'postExerciseHR': measurement.heartRate ?? 0,
        'rr': measurement.respiratoryRate ?? 0,
        'spo2': measurement.oxygenSaturation ?? 0,
      },
    );
    await _advanceToNextStep();
  }

  /// Save face scan measurement (1 of 3)
  Future<void> saveFaceScanMeasurement(FaceScanMeasurement measurement) async {
    if (_currentAssessment == null) return;

    final currentVitalSigns = _currentAssessment!.vitalSigns;
    final measurements = currentVitalSigns?.measurements ?? [];

    // Add new measurement
    final updatedMeasurements = [...measurements, measurement];

    final updatedVitalSigns = VitalSignsResults(
      measurements: updatedMeasurements,
    );

    _currentAssessment = _currentAssessment!.copyWith(
      vitalSigns: updatedVitalSigns,
    );

    LoggingService.success('Saved face scan', tag: 'HealthAssessmentOrch', context: {'count': updatedMeasurements.length, 'total': 3});

    // Just accumulate + advance. Lambda submission is deferred until the very
    // end (assessment summary screen) so the user only sees one results page.
    await _advanceToNextStep();
  }

  /// Advance to body scan step (called when entering body scan prep screen)
  Future<void> advanceToBodyScan() async {
    if (_currentAssessment == null) return;
    if (_currentStep == AssessmentStep.faceScan3) {
      LoggingService.info('Advancing from faceScan3 to bodyScan step', tag: 'HealthAssessmentOrch');
      await _advanceToNextStep();
    }
  }

  /// Save body scan results
  Future<void> saveBodyScan(BodyScanResult bodyScanResult) async {
    LoggingService.info('saveBodyScan entry', tag: 'HealthAssessmentOrch');
    if (_currentAssessment == null) {
      LoggingService.warning('saveBodyScan called with null assessment',
          tag: 'HealthAssessmentOrch');
      return;
    }
    _currentAssessment = _currentAssessment!.copyWith(
      bodyScanResult: bodyScanResult,
    );
    await _advanceToNextStep();
    LoggingService.success('saveBodyScan exit',
        tag: 'HealthAssessmentOrch',
        context: {'currentStep': _currentStep.toString()});
  }

  /// Skip optional body scan
  Future<void> skipBodyScan() async {
    _completedSteps.add(AssessmentStep.bodyScan);
    await _advanceToNextStep();
  }

  /// Generic in-place update of the current assessment. Used by the summary
  /// screen to stash the end-of-assessment Lambda result without going through
  /// a dedicated save method.
  Future<void> updateAssessment(
    HealthAssessment Function(HealthAssessment) mutate,
  ) async {
    if (_currentAssessment == null) return;
    _currentAssessment = mutate(_currentAssessment!);
    await _saveToStorage();
    notifyListeners();
  }

  /// Complete the entire assessment
  Future<void> completeAssessment() async {
    if (_currentAssessment == null) return;

    _currentAssessment = _currentAssessment!.copyWith(
      isComplete: true,
      completedAt: DateTime.now(),
      currentStep: _getStepIndex(AssessmentStep.complete),
    );

    // Capture the id before _clearCurrentAssessment nulls _currentAssessment.
    // Without this, the log line below threw `Null check operator used on a
    // null value` and the exception killed the caller's await — which is
    // what made Complete Assessment require two taps.
    final completedId = _currentAssessment!.id;

    await _saveToCompletedStorage();
    await _clearCurrentAssessment();

    LoggingService.success('Assessment completed',
        tag: 'HealthAssessmentOrch', context: {'id': completedId});
    notifyListeners();
  }

  /// Abandon current assessment
  Future<void> abandonAssessment() async {
    await _clearCurrentAssessment();
    notifyListeners();
  }

  /// Clear all steps after the specified step (for back navigation)
  /// This allows users to go back and re-do parts of the assessment
  Future<void> clearStepsAfter(AssessmentStep targetStep) async {
    if (_currentAssessment == null) return;

    LoggingService.info('Clearing steps after', tag: 'HealthAssessmentOrch', context: {'targetStep': targetStep.toString()});

    // Update current step to target
    _currentStep = targetStep;

    // Remove all completed steps after the target step
    final targetIndex = _getStepIndex(targetStep);
    _completedSteps.removeWhere((step) {
      return _getStepIndex(step) > targetIndex;
    });

    // Clear data for steps after target step
    final stepIndex = _getStepIndex(targetStep);

    // Clear anxiety survey if going back before it
    if (stepIndex < _getStepIndex(AssessmentStep.anxietySurvey)) {
      _currentAssessment = _currentAssessment!.copyWith(
        anxietySurvey: null,
      );
    }

    // Clear depression survey if going back before it
    if (stepIndex < _getStepIndex(AssessmentStep.depressionSurvey)) {
      _currentAssessment = _currentAssessment!.copyWith(
        depressionSurvey: null,
      );
    }

    // Clear fitness screening if going back before it
    if (stepIndex < _getStepIndex(AssessmentStep.fitnessScreening)) {
      _currentAssessment = _currentAssessment!.copyWith(
        fitnessTest: null,
      );
    }

    // Clear step test data if going back before step test
    if (stepIndex < _getStepIndex(AssessmentStep.stepTestPrep)) {
      if (_currentAssessment!.fitnessTest != null) {
        _currentAssessment = _currentAssessment!.copyWith(
          fitnessTest: _currentAssessment!.fitnessTest!.copyWith(
            stepHeightCm: null,
            restingHeartRate: null,
            postExerciseHeartRate: null,
            completedAt: null,
          ),
        );
      }
    }

    // Clear face scan data if going back before first face scan
    if (stepIndex < _getStepIndex(AssessmentStep.faceScan1)) {
      _currentAssessment = _currentAssessment!.copyWith(
        vitalSigns: null,
      );
    } else if (stepIndex < _getStepIndex(AssessmentStep.faceScan2)) {
      // Keep only first face scan if between scan 1 and 2
      final measurements = _currentAssessment!.vitalSigns?.measurements ?? [];
      if (measurements.length > 1) {
        _currentAssessment = _currentAssessment!.copyWith(
          vitalSigns: VitalSignsResults(
            measurements: [measurements.first],
          ),
        );
      }
    } else if (stepIndex < _getStepIndex(AssessmentStep.faceScan3)) {
      // Keep only first two face scans if between scan 2 and 3
      final measurements = _currentAssessment!.vitalSigns?.measurements ?? [];
      if (measurements.length > 2) {
        _currentAssessment = _currentAssessment!.copyWith(
          vitalSigns: VitalSignsResults(
            measurements: measurements.sublist(0, 2),
          ),
        );
      }
    }

    // Clear body scan if going back before it
    if (stepIndex < _getStepIndex(AssessmentStep.bodyScan)) {
      _currentAssessment = _currentAssessment!.copyWith(
        bodyScanResult: null,
      );
    }

    // Update assessment current step
    _currentAssessment = _currentAssessment!.copyWith(
      currentStep: targetIndex,
    );

    // Save and notify
    await _saveToStorage();
    notifyListeners();

    LoggingService.success('Cleared future steps', tag: 'HealthAssessmentOrch', context: {
      'newCurrentStep': _currentStep.toString(),
      'completedSteps': _completedSteps.length,
    });
  }

  /// Get the next step in the flow
  Future<void> _advanceToNextStep() async {
    // CRITICAL FIX: Guard against null assessment to prevent crashes
    if (_currentAssessment == null) {
      LoggingService.warning('Cannot advance step: no active assessment', tag: 'HealthAssessmentOrch');
      return;
    }

    _completedSteps.add(_currentStep);

    // Determine next step based on current step and conditions
    final nextStep = _getNextStep();

    if (nextStep != null) {
      _currentStep = nextStep;
      _currentAssessment = _currentAssessment!.copyWith(
        currentStep: _getStepIndex(nextStep),
      );
      await _saveToStorage();
      notifyListeners();
      LoggingService.info('Advanced to step', tag: 'HealthAssessmentOrch', context: {'step': _currentStep.toString()});
    } else {
      LoggingService.warning('No next step found, assessment may be complete', tag: 'HealthAssessmentOrch');
    }
  }

  /// Determine the next step based on current state.
  ///
  /// New flow (leaner — no break screens, step test moved to after body scan):
  ///   disclaimer → anxiety → depression → faceScan1 → faceScan2 → faceScan3 →
  ///   bodyScan → stepTestPrep → stepTestActive → postExerciseFaceScan →
  ///   summary → complete.
  ///
  /// `fitnessScreening` is no longer in the live flow — left in the switch
  /// only so persisted assessments that paused there can be resumed forward
  /// to stepTestPrep.
  AssessmentStep? _getNextStep() {
    switch (_currentStep) {
      case AssessmentStep.disclaimer:
        return AssessmentStep.anxietySurvey;

      case AssessmentStep.anxietySurvey:
        return AssessmentStep.depressionSurvey;

      case AssessmentStep.depressionSurvey:
        return AssessmentStep.faceScan1;

      case AssessmentStep.faceScan1:
        return AssessmentStep.faceScan2;

      // break1 / break2 stay in the enum for backwards-compat with stored
      // assessments but are no longer reachable from the linear flow.
      case AssessmentStep.break1:
        return AssessmentStep.faceScan2;

      case AssessmentStep.faceScan2:
        return AssessmentStep.faceScan3;

      case AssessmentStep.break2:
        return AssessmentStep.faceScan3;

      case AssessmentStep.faceScan3:
        return AssessmentStep.bodyScan;

      case AssessmentStep.bodyScan:
        return AssessmentStep.stepTestPrep;

      case AssessmentStep.fitnessScreening:
        // Legacy-only — the screening step is no longer reachable from the
        // live flow. Resume forward so old persisted sessions don't strand.
        return AssessmentStep.stepTestPrep;

      case AssessmentStep.stepTestPrep:
        return AssessmentStep.stepTestActive;

      case AssessmentStep.stepTestActive:
        return AssessmentStep.postExerciseFaceScan;

      case AssessmentStep.postExerciseFaceScan:
        return AssessmentStep.summary;

      case AssessmentStep.summary:
        return AssessmentStep.complete;

      case AssessmentStep.complete:
        return null;
    }
  }

  /// Get step index for storage
  int _getStepIndex(AssessmentStep step) {
    return AssessmentStep.values.indexOf(step);
  }

  /// Get step from index
  AssessmentStep _getStepFromIndex(int index) {
    if (index >= 0 && index < AssessmentStep.values.length) {
      return AssessmentStep.values[index];
    }
    return AssessmentStep.disclaimer;
  }

  /// Save current assessment to storage
  Future<void> _saveToStorage() async {
    if (_currentAssessment == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, _currentAssessment!.toJsonString());
      LoggingService.debug('Saved assessment to storage', tag: 'HealthAssessmentOrch');
    } catch (e) {
      LoggingService.error('Error saving assessment', error: e, tag: 'HealthAssessmentOrch');
    }
  }

  /// Save completed assessment to history
  Future<void> _saveToCompletedStorage() async {
    if (_currentAssessment == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyKey = 'assessment_history';
      final List<String> history = prefs.getStringList(historyKey) ?? [];
      history.insert(0, _currentAssessment!.toJsonString());

      // Keep only last 50 assessments
      if (history.length > 50) {
        history.removeRange(50, history.length);
      }

      await prefs.setStringList(historyKey, history);
      LoggingService.debug('Saved to assessment history', tag: 'HealthAssessmentOrch');
    } catch (e) {
      LoggingService.error('Error saving to history', error: e, tag: 'HealthAssessmentOrch');
    }
  }

  /// Clear current assessment from storage
  Future<void> _clearCurrentAssessment() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      _currentAssessment = null;
      _currentStep = AssessmentStep.disclaimer;
      _completedSteps.clear();
      LoggingService.info('Cleared current assessment', tag: 'HealthAssessmentOrch');
    } catch (e) {
      LoggingService.error('Error clearing assessment', error: e, tag: 'HealthAssessmentOrch');
    }
  }

  /// Get assessment history
  Future<List<HealthAssessment>> getAssessmentHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyKey = 'assessment_history';
      final List<String> history = prefs.getStringList(historyKey) ?? [];
      return history
          .map((json) => HealthAssessment.fromJsonString(json))
          .toList();
    } catch (e) {
      LoggingService.error('Error loading history', error: e, tag: 'HealthAssessmentOrch');
      return [];
    }
  }

  /// Check if a specific step is completed
  bool isStepCompleted(AssessmentStep step) {
    return _completedSteps.contains(step);
  }

  /// Get progress percentage (0.0 to 1.0)
  double get progress {
    if (_currentAssessment == null) return 0.0;
    final totalSteps = AssessmentStep.values.length - 1; // Exclude 'complete'
    final currentIndex = _getStepIndex(_currentStep);
    return currentIndex / totalSteps;
  }

  /// Get human-readable step name
  String getStepName(AssessmentStep step) {
    switch (step) {
      case AssessmentStep.disclaimer:
        return 'Disclaimer';
      case AssessmentStep.anxietySurvey:
        return 'Anxiety Survey (GAD-7)';
      case AssessmentStep.depressionSurvey:
        return 'Depression Survey (PHQ-9)';
      case AssessmentStep.fitnessScreening:
        return 'Fitness Screening (PAR-Q)';
      case AssessmentStep.stepTestPrep:
        return 'Step Test Preparation';
      case AssessmentStep.stepTestActive:
        return '3-Minute Step Test';
      case AssessmentStep.postExerciseFaceScan:
        return 'Post-Exercise Heart Rate';
      case AssessmentStep.faceScan1:
        return 'Face Scan 1/3';
      case AssessmentStep.break1:
        return 'Rest Break (60s)';
      case AssessmentStep.faceScan2:
        return 'Face Scan 2/3';
      case AssessmentStep.break2:
        return 'Rest Break (60s)';
      case AssessmentStep.faceScan3:
        return 'Face Scan 3/3';
      case AssessmentStep.bodyScan:
        return 'Body Scan (Optional)';
      case AssessmentStep.summary:
        return 'Results Summary';
      case AssessmentStep.complete:
        return 'Complete';
    }
  }
}

/// Enumeration of all assessment steps in order
enum AssessmentStep {
  disclaimer,           // 0 - Accept terms and disclaimers
  anxietySurvey,       // 1 - GAD-7 Anxiety Survey
  depressionSurvey,    // 2 - PHQ-9 Depression Survey
  fitnessScreening,    // 3 - PAR-Q Safety Questionnaire
  stepTestPrep,        // 4 - Step Test Preparation (conditional)
  stepTestActive,      // 5 - 3-Minute Step Test (conditional)
  postExerciseFaceScan,// 6 - Post-exercise heart rate (conditional)
  faceScan1,           // 7 - First resting face scan
  break1,              // 8 - 60-second break
  faceScan2,           // 9 - Second resting face scan
  break2,              // 10 - 60-second break
  faceScan3,           // 11 - Third resting face scan
  bodyScan,            // 12 - Body scan (optional)
  summary,             // 13 - Results summary
  complete,            // 14 - Assessment complete
}
