import 'dart:convert';

/// GAD-7 (Generalized Anxiety Disorder-7) Survey Result
///
/// 7-item survey to assess anxiety symptoms over the last two weeks.
/// Each item is scored 0-3:
/// - 0: Not at all
/// - 1: Several days
/// - 2: More than half the days
/// - 3: Nearly every day
///
/// Total score interpretation:
/// - 0-4: Minimal anxiety
/// - 5-9: Mild anxiety
/// - 10-14: Moderate anxiety
/// - 15-21: Severe anxiety
class AnxietySurveyResult {
  final String id;
  final DateTime completedAt;

  // Individual question scores (0-3 each)
  final int nervousAnxiousScore; // Q1: Feeling nervous, anxious, or on edge
  final int uncontrollableWorryScore; // Q2: Not being able to stop or control worrying
  final int worryingTooMuchScore; // Q3: Worrying too much about different things
  final int troubleRelaxingScore; // Q4: Trouble relaxing
  final int restlessnessScore; // Q5: Being so restless that it's hard to sit still
  final int easilyAnnoyedScore; // Q6: Becoming easily annoyed or irritable
  final int feelingAfraidScore; // Q7: Feeling afraid as if something awful might happen

  // Total score (sum of all questions, 0-21)
  int get totalScore =>
      nervousAnxiousScore +
      uncontrollableWorryScore +
      worryingTooMuchScore +
      troubleRelaxingScore +
      restlessnessScore +
      easilyAnnoyedScore +
      feelingAfraidScore;

  // Severity level based on total score
  String get severityLevel {
    if (totalScore <= 4) return 'minimal';
    if (totalScore <= 9) return 'mild';
    if (totalScore <= 14) return 'moderate';
    return 'severe';
  }

  // User-friendly severity description
  String get severityDescription {
    switch (severityLevel) {
      case 'minimal':
        return 'Minimal Anxiety';
      case 'mild':
        return 'Mild Anxiety';
      case 'moderate':
        return 'Moderate Anxiety';
      case 'severe':
        return 'Severe Anxiety';
      default:
        return 'Unknown';
    }
  }

  // Clinical guidance based on score
  String get clinicalGuidance {
    if (totalScore <= 4) {
      return 'Your anxiety levels appear minimal. Continue maintaining healthy lifestyle habits.';
    } else if (totalScore <= 9) {
      return 'You may be experiencing mild anxiety. Consider stress management techniques and monitoring your symptoms.';
    } else if (totalScore <= 14) {
      return 'You may be experiencing moderate anxiety. Consider consulting with a mental health professional.';
    } else {
      return 'You may be experiencing severe anxiety. We strongly recommend consulting with a mental health professional as soon as possible.';
    }
  }

  AnxietySurveyResult({
    required this.id,
    required this.completedAt,
    required this.nervousAnxiousScore,
    required this.uncontrollableWorryScore,
    required this.worryingTooMuchScore,
    required this.troubleRelaxingScore,
    required this.restlessnessScore,
    required this.easilyAnnoyedScore,
    required this.feelingAfraidScore,
  }) : assert(nervousAnxiousScore >= 0 && nervousAnxiousScore <= 3),
       assert(uncontrollableWorryScore >= 0 && uncontrollableWorryScore <= 3),
       assert(worryingTooMuchScore >= 0 && worryingTooMuchScore <= 3),
       assert(troubleRelaxingScore >= 0 && troubleRelaxingScore <= 3),
       assert(restlessnessScore >= 0 && restlessnessScore <= 3),
       assert(easilyAnnoyedScore >= 0 && easilyAnnoyedScore <= 3),
       assert(feelingAfraidScore >= 0 && feelingAfraidScore <= 3);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'completedAt': completedAt.toIso8601String(),
      'nervousAnxiousScore': nervousAnxiousScore,
      'uncontrollableWorryScore': uncontrollableWorryScore,
      'worryingTooMuchScore': worryingTooMuchScore,
      'troubleRelaxingScore': troubleRelaxingScore,
      'restlessnessScore': restlessnessScore,
      'easilyAnnoyedScore': easilyAnnoyedScore,
      'feelingAfraidScore': feelingAfraidScore,
      'totalScore': totalScore,
      'severityLevel': severityLevel,
    };
  }

  factory AnxietySurveyResult.fromJson(Map<String, dynamic> json) {
    return AnxietySurveyResult(
      id: json['id'] ?? '',
      completedAt: DateTime.tryParse(json['completedAt'] ?? '') ?? DateTime.now(),
      nervousAnxiousScore: json['nervousAnxiousScore'] ?? 0,
      uncontrollableWorryScore: json['uncontrollableWorryScore'] ?? 0,
      worryingTooMuchScore: json['worryingTooMuchScore'] ?? 0,
      troubleRelaxingScore: json['troubleRelaxingScore'] ?? 0,
      restlessnessScore: json['restlessnessScore'] ?? 0,
      easilyAnnoyedScore: json['easilyAnnoyedScore'] ?? 0,
      feelingAfraidScore: json['feelingAfraidScore'] ?? 0,
    );
  }

  String toJsonString() => json.encode(toJson());

  factory AnxietySurveyResult.fromJsonString(String jsonString) {
    return AnxietySurveyResult.fromJson(json.decode(jsonString));
  }

  @override
  String toString() {
    return 'AnxietySurveyResult(id: $id, totalScore: $totalScore, severity: $severityLevel)';
  }
}
