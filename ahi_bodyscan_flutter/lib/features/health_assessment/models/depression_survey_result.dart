import 'dart:convert';

/// PHQ-9 (Patient Health Questionnaire-9) Survey Result
///
/// 9-item survey to assess depression symptoms over the last two weeks.
/// Each item is scored 0-3:
/// - 0: Not at all
/// - 1: Several days
/// - 2: More than half the days
/// - 3: Nearly every day
///
/// Total score interpretation:
/// - 0-4: Minimal depression
/// - 5-9: Mild depression
/// - 10-14: Moderate depression
/// - 15-19: Moderately severe depression
/// - 20-27: Severe depression
class DepressionSurveyResult {
  final String id;
  final DateTime completedAt;

  // Individual question scores (0-3 each)
  final int littleInterestScore; // Q1: Little interest or pleasure in doing things
  final int feelingDownScore; // Q2: Feeling down, depressed, or hopeless
  final int sleepProblemsScore; // Q3: Trouble falling/staying asleep or sleeping too much
  final int tiredLowEnergyScore; // Q4: Feeling tired or having little energy
  final int appetiteProblemsScore; // Q5: Poor appetite or overeating
  final int feelingBadAboutSelfScore; // Q6: Feeling bad about yourself or that you're a failure
  final int concentrationProblemsScore; // Q7: Trouble concentrating on things
  final int movementProblemsScore; // Q8: Moving/speaking slowly or being fidgety/restless
  final int selfHarmThoughtsScore; // Q9: Thoughts of hurting yourself or being better off dead

  // Total score (sum of all questions, 0-27)
  int get totalScore =>
      littleInterestScore +
      feelingDownScore +
      sleepProblemsScore +
      tiredLowEnergyScore +
      appetiteProblemsScore +
      feelingBadAboutSelfScore +
      concentrationProblemsScore +
      movementProblemsScore +
      selfHarmThoughtsScore;

  // Severity level based on total score
  String get severityLevel {
    if (totalScore <= 4) return 'minimal';
    if (totalScore <= 9) return 'mild';
    if (totalScore <= 14) return 'moderate';
    if (totalScore <= 19) return 'moderately_severe';
    return 'severe';
  }

  // User-friendly severity description
  String get severityDescription {
    switch (severityLevel) {
      case 'minimal':
        return 'Minimal Depression';
      case 'mild':
        return 'Mild Depression';
      case 'moderate':
        return 'Moderate Depression';
      case 'moderately_severe':
        return 'Moderately Severe Depression';
      case 'severe':
        return 'Severe Depression';
      default:
        return 'Unknown';
    }
  }

  // Check if self-harm thoughts were reported (critical flag)
  bool get hasSelfHarmThoughts => selfHarmThoughtsScore > 0;

  // Clinical guidance based on score
  String get clinicalGuidance {
    // Critical: Self-harm thoughts
    if (hasSelfHarmThoughts) {
      return 'IMPORTANT: You have indicated thoughts of self-harm. Please seek immediate help from a mental health professional or call a crisis hotline. Your safety is the top priority.';
    }

    if (totalScore <= 4) {
      return 'Your depression levels appear minimal. Continue maintaining healthy lifestyle habits.';
    } else if (totalScore <= 9) {
      return 'You may be experiencing mild depression. Consider monitoring your symptoms and talking to someone you trust.';
    } else if (totalScore <= 14) {
      return 'You may be experiencing moderate depression. We recommend consulting with a mental health professional.';
    } else if (totalScore <= 19) {
      return 'You may be experiencing moderately severe depression. We strongly recommend consulting with a mental health professional soon.';
    } else {
      return 'You may be experiencing severe depression. We strongly recommend consulting with a mental health professional as soon as possible.';
    }
  }

  DepressionSurveyResult({
    required this.id,
    required this.completedAt,
    required this.littleInterestScore,
    required this.feelingDownScore,
    required this.sleepProblemsScore,
    required this.tiredLowEnergyScore,
    required this.appetiteProblemsScore,
    required this.feelingBadAboutSelfScore,
    required this.concentrationProblemsScore,
    required this.movementProblemsScore,
    required this.selfHarmThoughtsScore,
  }) : assert(littleInterestScore >= 0 && littleInterestScore <= 3),
       assert(feelingDownScore >= 0 && feelingDownScore <= 3),
       assert(sleepProblemsScore >= 0 && sleepProblemsScore <= 3),
       assert(tiredLowEnergyScore >= 0 && tiredLowEnergyScore <= 3),
       assert(appetiteProblemsScore >= 0 && appetiteProblemsScore <= 3),
       assert(feelingBadAboutSelfScore >= 0 && feelingBadAboutSelfScore <= 3),
       assert(concentrationProblemsScore >= 0 && concentrationProblemsScore <= 3),
       assert(movementProblemsScore >= 0 && movementProblemsScore <= 3),
       assert(selfHarmThoughtsScore >= 0 && selfHarmThoughtsScore <= 3);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'completedAt': completedAt.toIso8601String(),
      'littleInterestScore': littleInterestScore,
      'feelingDownScore': feelingDownScore,
      'sleepProblemsScore': sleepProblemsScore,
      'tiredLowEnergyScore': tiredLowEnergyScore,
      'appetiteProblemsScore': appetiteProblemsScore,
      'feelingBadAboutSelfScore': feelingBadAboutSelfScore,
      'concentrationProblemsScore': concentrationProblemsScore,
      'movementProblemsScore': movementProblemsScore,
      'selfHarmThoughtsScore': selfHarmThoughtsScore,
      'totalScore': totalScore,
      'severityLevel': severityLevel,
      'hasSelfHarmThoughts': hasSelfHarmThoughts,
    };
  }

  factory DepressionSurveyResult.fromJson(Map<String, dynamic> json) {
    return DepressionSurveyResult(
      id: json['id'] ?? '',
      completedAt: DateTime.tryParse(json['completedAt'] ?? '') ?? DateTime.now(),
      littleInterestScore: json['littleInterestScore'] ?? 0,
      feelingDownScore: json['feelingDownScore'] ?? 0,
      sleepProblemsScore: json['sleepProblemsScore'] ?? 0,
      tiredLowEnergyScore: json['tiredLowEnergyScore'] ?? 0,
      appetiteProblemsScore: json['appetiteProblemsScore'] ?? 0,
      feelingBadAboutSelfScore: json['feelingBadAboutSelfScore'] ?? 0,
      concentrationProblemsScore: json['concentrationProblemsScore'] ?? 0,
      movementProblemsScore: json['movementProblemsScore'] ?? 0,
      selfHarmThoughtsScore: json['selfHarmThoughtsScore'] ?? 0,
    );
  }

  String toJsonString() => json.encode(toJson());

  factory DepressionSurveyResult.fromJsonString(String jsonString) {
    return DepressionSurveyResult.fromJson(json.decode(jsonString));
  }

  @override
  String toString() {
    return 'DepressionSurveyResult(id: $id, totalScore: $totalScore, severity: $severityLevel)';
  }
}
