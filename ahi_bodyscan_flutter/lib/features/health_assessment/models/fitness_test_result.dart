import 'dart:convert';

/// Fitness Test Result including PAR-Q screening and 3-minute step test
///
/// Combines safety screening (PAR-Q) and cardiorespiratory fitness assessment
/// via the 3-minute step test with post-exercise heart rate recovery.
class FitnessTestResult {
  final String id;
  final DateTime completedAt;

  // PAR-Q (Physical Activity Readiness Questionnaire) - 7 safety questions
  final bool hasHeartCondition; // Q1: Heart condition requiring doctor supervision
  final bool hasChestPainDuringActivity; // Q2: Chest pain during physical activity
  final bool hasChestPainWhenInactive; // Q3: Chest pain in past month when inactive
  final bool hasDizzinessOrLossOfConsciousness; // Q4: Dizziness or loss of consciousness
  final bool hasBoneOrJointProblem; // Q5: Bone/joint problem that could worsen
  final bool takesPrescriptionDrugs; // Q6: Takes blood pressure or heart medication
  final bool hasOtherReason; // Q7: Any other reason not to do physical activity

  // Check if safe to proceed with step test (all answers should be "no")
  bool get isSafeForExercise =>
      !hasHeartCondition &&
      !hasChestPainDuringActivity &&
      !hasChestPainWhenInactive &&
      !hasDizzinessOrLossOfConsciousness &&
      !hasBoneOrJointProblem &&
      !takesPrescriptionDrugs &&
      !hasOtherReason;

  // Step Test Parameters
  final double? stepHeightCm; // Height of step used (15-51 cm)
  final bool? testCompleted; // Whether 3-minute test was completed
  final int? testDurationSeconds; // Actual duration if test was stopped early

  // Post-Exercise Heart Rate
  final int? postExerciseHeartRate; // BPM immediately after step test
  final int? restingHeartRate; // BPM at rest (from baseline face scan)

  // Calculated metrics
  int? get heartRateRecovery {
    if (postExerciseHeartRate == null || restingHeartRate == null) return null;
    return postExerciseHeartRate! - restingHeartRate!;
  }

  // Fitness level based on heart rate recovery
  // Lower recovery = better fitness
  String? get fitnessLevel {
    if (heartRateRecovery == null) return null;
    final recovery = heartRateRecovery!;

    // These are approximate values - adjust based on research
    if (recovery < 20) return 'excellent';
    if (recovery < 30) return 'good';
    if (recovery < 40) return 'average';
    if (recovery < 50) return 'below_average';
    return 'poor';
  }

  String? get fitnessLevelDescription {
    if (fitnessLevel == null) return null;
    switch (fitnessLevel) {
      case 'excellent':
        return 'Excellent Cardio Fitness';
      case 'good':
        return 'Good Cardio Fitness';
      case 'average':
        return 'Average Cardio Fitness';
      case 'below_average':
        return 'Below Average Cardio Fitness';
      case 'poor':
        return 'Poor Cardio Fitness';
      default:
        return 'Unknown';
    }
  }

  FitnessTestResult({
    required this.id,
    required this.completedAt,
    required this.hasHeartCondition,
    required this.hasChestPainDuringActivity,
    required this.hasChestPainWhenInactive,
    required this.hasDizzinessOrLossOfConsciousness,
    required this.hasBoneOrJointProblem,
    required this.takesPrescriptionDrugs,
    required this.hasOtherReason,
    this.stepHeightCm,
    this.testCompleted,
    this.testDurationSeconds,
    this.postExerciseHeartRate,
    this.restingHeartRate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'completedAt': completedAt.toIso8601String(),
      'hasHeartCondition': hasHeartCondition,
      'hasChestPainDuringActivity': hasChestPainDuringActivity,
      'hasChestPainWhenInactive': hasChestPainWhenInactive,
      'hasDizzinessOrLossOfConsciousness': hasDizzinessOrLossOfConsciousness,
      'hasBoneOrJointProblem': hasBoneOrJointProblem,
      'takesPrescriptionDrugs': takesPrescriptionDrugs,
      'hasOtherReason': hasOtherReason,
      'isSafeForExercise': isSafeForExercise,
      'stepHeightCm': stepHeightCm,
      'testCompleted': testCompleted,
      'testDurationSeconds': testDurationSeconds,
      'postExerciseHeartRate': postExerciseHeartRate,
      'restingHeartRate': restingHeartRate,
      'heartRateRecovery': heartRateRecovery,
      'fitnessLevel': fitnessLevel,
    };
  }

  factory FitnessTestResult.fromJson(Map<String, dynamic> json) {
    return FitnessTestResult(
      id: json['id'] ?? '',
      completedAt: DateTime.tryParse(json['completedAt'] ?? '') ?? DateTime.now(),
      hasHeartCondition: json['hasHeartCondition'] ?? false,
      hasChestPainDuringActivity: json['hasChestPainDuringActivity'] ?? false,
      hasChestPainWhenInactive: json['hasChestPainWhenInactive'] ?? false,
      hasDizzinessOrLossOfConsciousness: json['hasDizzinessOrLossOfConsciousness'] ?? false,
      hasBoneOrJointProblem: json['hasBoneOrJointProblem'] ?? false,
      takesPrescriptionDrugs: json['takesPrescriptionDrugs'] ?? false,
      hasOtherReason: json['hasOtherReason'] ?? false,
      stepHeightCm: json['stepHeightCm']?.toDouble(),
      testCompleted: json['testCompleted'],
      testDurationSeconds: json['testDurationSeconds'],
      postExerciseHeartRate: json['postExerciseHeartRate'],
      restingHeartRate: json['restingHeartRate'],
    );
  }

  String toJsonString() => json.encode(toJson());

  factory FitnessTestResult.fromJsonString(String jsonString) {
    return FitnessTestResult.fromJson(json.decode(jsonString));
  }

  FitnessTestResult copyWith({
    String? id,
    DateTime? completedAt,
    bool? hasHeartCondition,
    bool? hasChestPainDuringActivity,
    bool? hasChestPainWhenInactive,
    bool? hasDizzinessOrLossOfConsciousness,
    bool? hasBoneOrJointProblem,
    bool? takesPrescriptionDrugs,
    bool? hasOtherReason,
    double? stepHeightCm,
    bool? testCompleted,
    int? testDurationSeconds,
    int? postExerciseHeartRate,
    int? restingHeartRate,
  }) {
    return FitnessTestResult(
      id: id ?? this.id,
      completedAt: completedAt ?? this.completedAt,
      hasHeartCondition: hasHeartCondition ?? this.hasHeartCondition,
      hasChestPainDuringActivity: hasChestPainDuringActivity ?? this.hasChestPainDuringActivity,
      hasChestPainWhenInactive: hasChestPainWhenInactive ?? this.hasChestPainWhenInactive,
      hasDizzinessOrLossOfConsciousness: hasDizzinessOrLossOfConsciousness ?? this.hasDizzinessOrLossOfConsciousness,
      hasBoneOrJointProblem: hasBoneOrJointProblem ?? this.hasBoneOrJointProblem,
      takesPrescriptionDrugs: takesPrescriptionDrugs ?? this.takesPrescriptionDrugs,
      hasOtherReason: hasOtherReason ?? this.hasOtherReason,
      stepHeightCm: stepHeightCm ?? this.stepHeightCm,
      testCompleted: testCompleted ?? this.testCompleted,
      testDurationSeconds: testDurationSeconds ?? this.testDurationSeconds,
      postExerciseHeartRate: postExerciseHeartRate ?? this.postExerciseHeartRate,
      restingHeartRate: restingHeartRate ?? this.restingHeartRate,
    );
  }

  @override
  String toString() {
    return 'FitnessTestResult(id: $id, safe: $isSafeForExercise, fitness: $fitnessLevel)';
  }
}
