//
//  AHI BHA Models - Biological Health Assessment data structures
//
//  Copyright (c) AHI. All rights reserved.
//

import 'package:equatable/equatable.dart';

/// BHA Risk Level
enum BHARiskLevel {
  low,
  moderate,
  high,
  unknown,
}

extension BHARiskLevelExtension on BHARiskLevel {
  String get label {
    switch (this) {
      case BHARiskLevel.low:
        return 'Low Risk';
      case BHARiskLevel.moderate:
        return 'Moderate Risk';
      case BHARiskLevel.high:
        return 'High Risk';
      case BHARiskLevel.unknown:
        return 'Unknown';
    }
  }

  String get color {
    switch (this) {
      case BHARiskLevel.low:
        return '#4CAF50'; // Green
      case BHARiskLevel.moderate:
        return '#FFA726'; // Orange
      case BHARiskLevel.high:
        return '#E53935'; // Red
      case BHARiskLevel.unknown:
        return '#757575'; // Grey
    }
  }
}

/// BHA Risk Category
enum BHARiskCategory {
  cardiovascular,
  metabolic,
  mentalHealth,
  bodyComposition,
  fitness,
}

extension BHARiskCategoryExtension on BHARiskCategory {
  String get label {
    switch (this) {
      case BHARiskCategory.cardiovascular:
        return 'Cardiovascular';
      case BHARiskCategory.metabolic:
        return 'Metabolic';
      case BHARiskCategory.mentalHealth:
        return 'Mental Health';
      case BHARiskCategory.bodyComposition:
        return 'Body Composition';
      case BHARiskCategory.fitness:
        return 'Fitness';
    }
  }

  String get icon {
    switch (this) {
      case BHARiskCategory.cardiovascular:
        return '❤️';
      case BHARiskCategory.metabolic:
        return '⚡';
      case BHARiskCategory.mentalHealth:
        return '🧠';
      case BHARiskCategory.bodyComposition:
        return '🏃';
      case BHARiskCategory.fitness:
        return '💪';
    }
  }
}

/// Individual BHA risk assessment
class BHARiskAssessment extends Equatable {
  const BHARiskAssessment({
    required this.category,
    required this.riskLevel,
    required this.score,
    required this.title,
    required this.description,
    this.recommendations = const [],
    this.metrics = const {},
  });

  final BHARiskCategory category;
  final BHARiskLevel riskLevel;
  final double score; // 0-100
  final String title;
  final String description;
  final List<String> recommendations;
  final Map<String, dynamic> metrics;

  @override
  List<Object?> get props => [
        category,
        riskLevel,
        score,
        title,
        description,
        recommendations,
        metrics,
      ];

  Map<String, dynamic> toJson() {
    return {
      'category': category.name,
      'riskLevel': riskLevel.name,
      'score': score,
      'title': title,
      'description': description,
      'recommendations': recommendations,
      'metrics': metrics,
    };
  }

  factory BHARiskAssessment.fromJson(Map<String, dynamic> json) {
    return BHARiskAssessment(
      category: BHARiskCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => BHARiskCategory.cardiovascular,
      ),
      riskLevel: BHARiskLevel.values.firstWhere(
        (e) => e.name == json['riskLevel'],
        orElse: () => BHARiskLevel.unknown,
      ),
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      recommendations: List<String>.from(json['recommendations'] ?? []),
      metrics: Map<String, dynamic>.from(json['metrics'] ?? {}),
    );
  }
}

/// Complete BHA profile
class BHAProfile extends Equatable {
  const BHAProfile({
    required this.userId,
    required this.assessmentDate,
    required this.overallScore,
    required this.overallRiskLevel,
    required this.riskAssessments,
    this.recommendations = const [],
    this.nextAssessmentDate,
  });

  final String userId;
  final DateTime assessmentDate;
  final double overallScore; // 0-100
  final BHARiskLevel overallRiskLevel;
  final List<BHARiskAssessment> riskAssessments;
  final List<String> recommendations;
  final DateTime? nextAssessmentDate;

  /// Get risk assessments by category
  List<BHARiskAssessment> getRiskAssessmentsByCategory(BHARiskCategory category) {
    return riskAssessments.where((assessment) => assessment.category == category).toList();
  }

  /// Get highest risk level across all assessments
  BHARiskLevel get highestRiskLevel {
    if (riskAssessments.isEmpty) return BHARiskLevel.unknown;
    
    final risks = riskAssessments.map((a) => a.riskLevel).toSet();
    
    if (risks.contains(BHARiskLevel.high)) return BHARiskLevel.high;
    if (risks.contains(BHARiskLevel.moderate)) return BHARiskLevel.moderate;
    if (risks.contains(BHARiskLevel.low)) return BHARiskLevel.low;
    
    return BHARiskLevel.unknown;
  }

  /// Get category scores
  Map<BHARiskCategory, double> get categoryScores {
    final Map<BHARiskCategory, List<double>> categoryScoresList = {};
    
    for (final assessment in riskAssessments) {
      categoryScoresList.putIfAbsent(assessment.category, () => []).add(assessment.score);
    }
    
    final Map<BHARiskCategory, double> averageScores = {};
    for (final entry in categoryScoresList.entries) {
      final average = entry.value.reduce((a, b) => a + b) / entry.value.length;
      averageScores[entry.key] = average;
    }
    
    return averageScores;
  }

  @override
  List<Object?> get props => [
        userId,
        assessmentDate,
        overallScore,
        overallRiskLevel,
        riskAssessments,
        recommendations,
        nextAssessmentDate,
      ];

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'assessmentDate': assessmentDate.toIso8601String(),
      'overallScore': overallScore,
      'overallRiskLevel': overallRiskLevel.name,
      'riskAssessments': riskAssessments.map((a) => a.toJson()).toList(),
      'recommendations': recommendations,
      'nextAssessmentDate': nextAssessmentDate?.toIso8601String(),
    };
  }

  factory BHAProfile.fromJson(Map<String, dynamic> json) {
    return BHAProfile(
      userId: json['userId'] as String? ?? '',
      assessmentDate: DateTime.parse(json['assessmentDate'] as String? ?? DateTime.now().toIso8601String()),
      overallScore: (json['overallScore'] as num?)?.toDouble() ?? 0.0,
      overallRiskLevel: BHARiskLevel.values.firstWhere(
        (e) => e.name == json['overallRiskLevel'],
        orElse: () => BHARiskLevel.unknown,
      ),
      riskAssessments: (json['riskAssessments'] as List?)
          ?.map((a) => BHARiskAssessment.fromJson(a))
          .toList() ?? [],
      recommendations: List<String>.from(json['recommendations'] ?? []),
      nextAssessmentDate: json['nextAssessmentDate'] != null 
          ? DateTime.parse(json['nextAssessmentDate'])
          : null,
    );
  }
}

/// BHA Survey Response
class BHASurveyResponse extends Equatable {
  const BHASurveyResponse({
    required this.questionId,
    required this.response,
    this.score,
  });

  final String questionId;
  final dynamic response; // Can be String, int, bool, or List
  final double? score;

  @override
  List<Object?> get props => [questionId, response, score];

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'response': response,
      'score': score,
    };
  }

  factory BHASurveyResponse.fromJson(Map<String, dynamic> json) {
    return BHASurveyResponse(
      questionId: json['questionId'] as String? ?? '',
      response: json['response'],
      score: (json['score'] as num?)?.toDouble(),
    );
  }
}