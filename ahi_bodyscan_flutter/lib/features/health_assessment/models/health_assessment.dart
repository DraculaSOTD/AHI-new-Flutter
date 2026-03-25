import 'dart:convert';
import 'anxiety_survey_result.dart';
import 'depression_survey_result.dart';
import 'fitness_test_result.dart';
import '../../../services/ahi_scanner/models/scan_results.dart';

/// Comprehensive Health Assessment combining mental health surveys,
/// fitness testing, and vital signs monitoring
///
/// This model represents the complete health assessment flow:
/// 1. Anxiety Survey (GAD-7)
/// 2. Depression Survey (PHQ-9)
/// 3. Fitness Screening (PAR-Q)
/// 4. 3-Minute Step Test (optional)
/// 5. Vital Signs Monitoring (3x face scans with breaks)
/// 6. Optional Body Scan
class HealthAssessment {
  final String id;
  final String profileId; // Associated user profile
  final DateTime startedAt;
  final DateTime? completedAt;

  // Assessment status
  final bool isComplete;
  final int currentStep; // Current step in the flow (0-7)

  // Survey Results
  final AnxietySurveyResult? anxietySurvey;
  final DepressionSurveyResult? depressionSurvey;

  // Fitness Results
  final FitnessTestResult? fitnessTest;

  // Vital Signs (from 3x face scans)
  final VitalSignsResults? vitalSigns;

  // Optional: Body scan results
  final BodyScanResult? bodyScanResult; // Full body scan result with measurements

  // Lambda Health Assessment (if available)
  final Map<String, dynamic>? lambdaAssessment;

  HealthAssessment({
    required this.id,
    required this.profileId,
    required this.startedAt,
    this.completedAt,
    this.isComplete = false,
    this.currentStep = 0,
    this.anxietySurvey,
    this.depressionSurvey,
    this.fitnessTest,
    this.vitalSigns,
    this.bodyScanResult,
    this.lambdaAssessment,
  });

  // Check if assessment has critical mental health flags
  bool get hasCriticalFlags {
    if (depressionSurvey?.hasSelfHarmThoughts == true) return true;
    if (anxietySurvey != null && anxietySurvey!.totalScore >= 15) return true;
    if (depressionSurvey != null && depressionSurvey!.totalScore >= 15) return true;
    return false;
  }

  // Overall health risk level
  String get overallRiskLevel {
    if (hasCriticalFlags) return 'critical';

    int riskPoints = 0;

    // Mental health scoring
    if (anxietySurvey != null) {
      if (anxietySurvey!.totalScore >= 10) riskPoints += 2;
      else if (anxietySurvey!.totalScore >= 5) riskPoints += 1;
    }
    if (depressionSurvey != null) {
      if (depressionSurvey!.totalScore >= 10) riskPoints += 2;
      else if (depressionSurvey!.totalScore >= 5) riskPoints += 1;
    }

    // Fitness scoring
    if (fitnessTest != null && !fitnessTest!.isSafeForExercise) {
      riskPoints += 2;
    }
    if (fitnessTest?.fitnessLevel == 'poor') riskPoints += 2;
    else if (fitnessTest?.fitnessLevel == 'below_average') riskPoints += 1;

    // Vital signs scoring
    if (vitalSigns != null) {
      if (vitalSigns!.averageHeartRate != null) {
        if (vitalSigns!.averageHeartRate! > 100 || vitalSigns!.averageHeartRate! < 60) {
          riskPoints += 1;
        }
      }
      if (vitalSigns!.averageSystolicBP != null) {
        if (vitalSigns!.averageSystolicBP! > 140 || vitalSigns!.averageSystolicBP! < 90) {
          riskPoints += 2;
        }
      }
    }

    // Determine overall risk
    if (riskPoints >= 6) return 'high';
    if (riskPoints >= 3) return 'moderate';
    return 'low';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profileId': profileId,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'isComplete': isComplete,
      'currentStep': currentStep,
      'anxietySurvey': anxietySurvey?.toJson(),
      'depressionSurvey': depressionSurvey?.toJson(),
      'fitnessTest': fitnessTest?.toJson(),
      'vitalSigns': vitalSigns?.toJson(),
      'bodyScanResult': bodyScanResult?.toJson(),
      'lambdaAssessment': lambdaAssessment,
      'hasCriticalFlags': hasCriticalFlags,
      'overallRiskLevel': overallRiskLevel,
    };
  }

  factory HealthAssessment.fromJson(Map<String, dynamic> json) {
    return HealthAssessment(
      id: json['id'] ?? '',
      profileId: json['profileId'] ?? '',
      startedAt: DateTime.tryParse(json['startedAt'] ?? '') ?? DateTime.now(),
      completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt']) : null,
      isComplete: json['isComplete'] ?? false,
      currentStep: json['currentStep'] ?? 0,
      anxietySurvey: json['anxietySurvey'] != null
          ? AnxietySurveyResult.fromJson(json['anxietySurvey'])
          : null,
      depressionSurvey: json['depressionSurvey'] != null
          ? DepressionSurveyResult.fromJson(json['depressionSurvey'])
          : null,
      fitnessTest: json['fitnessTest'] != null
          ? FitnessTestResult.fromJson(json['fitnessTest'])
          : null,
      vitalSigns: json['vitalSigns'] != null
          ? VitalSignsResults.fromJson(json['vitalSigns'])
          : null,
      bodyScanResult: json['bodyScanResult'] != null
          ? BodyScanResult.fromObject(json['bodyScanResult'])
          : null,
      lambdaAssessment: json['lambdaAssessment'],
    );
  }

  String toJsonString() => json.encode(toJson());

  factory HealthAssessment.fromJsonString(String jsonString) {
    return HealthAssessment.fromJson(json.decode(jsonString));
  }

  HealthAssessment copyWith({
    String? id,
    String? profileId,
    DateTime? startedAt,
    DateTime? completedAt,
    bool? isComplete,
    int? currentStep,
    AnxietySurveyResult? anxietySurvey,
    DepressionSurveyResult? depressionSurvey,
    FitnessTestResult? fitnessTest,
    VitalSignsResults? vitalSigns,
    BodyScanResult? bodyScanResult,
    Map<String, dynamic>? lambdaAssessment,
  }) {
    return HealthAssessment(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      isComplete: isComplete ?? this.isComplete,
      currentStep: currentStep ?? this.currentStep,
      anxietySurvey: anxietySurvey ?? this.anxietySurvey,
      depressionSurvey: depressionSurvey ?? this.depressionSurvey,
      fitnessTest: fitnessTest ?? this.fitnessTest,
      vitalSigns: vitalSigns ?? this.vitalSigns,
      bodyScanResult: bodyScanResult ?? this.bodyScanResult,
      lambdaAssessment: lambdaAssessment ?? this.lambdaAssessment,
    );
  }

  @override
  String toString() {
    return 'HealthAssessment(id: $id, complete: $isComplete, step: $currentStep, risk: $overallRiskLevel)';
  }
}

/// Vital Signs Results from 3 consecutive face scans
///
/// Represents averaged vital signs from three 60-second face scans
/// with 60-second breaks between each scan.
class VitalSignsResults {
  final List<FaceScanMeasurement> measurements; // 3 scan results

  VitalSignsResults({
    required this.measurements,
  }) : assert(measurements.length <= 3, 'Maximum 3 measurements allowed');

  // Averaged vital signs
  double? get averageHeartRate {
    final values = measurements.map((m) => m.heartRate).whereType<int>().toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double? get averageSystolicBP {
    final values = measurements.map((m) => m.systolicBP).whereType<int>().toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double? get averageDiastolicBP {
    final values = measurements.map((m) => m.diastolicBP).whereType<int>().toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double? get averageRespiratoryRate {
    final values = measurements.map((m) => m.respiratoryRate).whereType<int>().toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double? get averageOxygenSaturation {
    final values = measurements.map((m) => m.oxygenSaturation).whereType<int>().toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double? get averageHRV {
    final values = measurements.map((m) => m.heartRateVariability).whereType<double>().toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double? get averageStressLevel {
    final values = measurements.map((m) => m.stressLevel).whereType<double>().toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  Map<String, dynamic> toJson() {
    return {
      'measurements': measurements.map((m) => m.toJson()).toList(),
      'averageHeartRate': averageHeartRate,
      'averageSystolicBP': averageSystolicBP,
      'averageDiastolicBP': averageDiastolicBP,
      'averageRespiratoryRate': averageRespiratoryRate,
      'averageOxygenSaturation': averageOxygenSaturation,
      'averageHRV': averageHRV,
      'averageStressLevel': averageStressLevel,
    };
  }

  factory VitalSignsResults.fromJson(Map<String, dynamic> json) {
    return VitalSignsResults(
      measurements: (json['measurements'] as List<dynamic>?)
              ?.map((m) => FaceScanMeasurement.fromJson(m))
              .toList() ??
          [],
    );
  }
}

/// Single face scan measurement (60 seconds)
class FaceScanMeasurement {
  final DateTime timestamp;
  final int? heartRate; // BPM
  final int? systolicBP; // mmHg
  final int? diastolicBP; // mmHg
  final int? respiratoryRate; // breaths/min
  final int? oxygenSaturation; // SpO2 %
  final double? heartRateVariability; // HRV (SDNN)
  final double? stressLevel; // 0-10 scale

  FaceScanMeasurement({
    required this.timestamp,
    this.heartRate,
    this.systolicBP,
    this.diastolicBP,
    this.respiratoryRate,
    this.oxygenSaturation,
    this.heartRateVariability,
    this.stressLevel,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'heartRate': heartRate,
      'systolicBP': systolicBP,
      'diastolicBP': diastolicBP,
      'respiratoryRate': respiratoryRate,
      'oxygenSaturation': oxygenSaturation,
      'heartRateVariability': heartRateVariability,
      'stressLevel': stressLevel,
    };
  }

  factory FaceScanMeasurement.fromJson(Map<String, dynamic> json) {
    return FaceScanMeasurement(
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      heartRate: json['heartRate'],
      systolicBP: json['systolicBP'],
      diastolicBP: json['diastolicBP'],
      respiratoryRate: json['respiratoryRate'],
      oxygenSaturation: json['oxygenSaturation'],
      heartRateVariability: json['heartRateVariability']?.toDouble(),
      stressLevel: json['stressLevel']?.toDouble(),
    );
  }

  /// Create from Vastmindz SDK result
  factory FaceScanMeasurement.fromVastmindzResult(Map<String, dynamic> result) {
    return FaceScanMeasurement(
      timestamp: DateTime.now(),
      heartRate: result['heartRate'],
      systolicBP: result['systolicBP'],
      diastolicBP: result['diastolicBP'],
      respiratoryRate: result['respiratoryRate'],
      oxygenSaturation: result['oxygenSaturation'],
      heartRateVariability: result['heartRateVariability']?.toDouble() ??
                           result['sdnn']?.toDouble(),
      stressLevel: result['stressLevel']?.toDouble(),
    );
  }
}
