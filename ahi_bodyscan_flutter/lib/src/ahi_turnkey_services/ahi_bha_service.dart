//
//  AHI BHA Service - Biological Health Assessment calculations and risk analysis
//
//  Copyright (c) AHI. All rights reserved.
//

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../ahi_turnkey_models/bha/ahi_bha_model.dart';
import '../models/ahi_user_data.dart';

class AHIBHAService {
  static final AHIBHAService _instance = AHIBHAService._internal();
  factory AHIBHAService() => _instance;
  AHIBHAService._internal();

  /// Generate comprehensive BHA profile from scan results and user data
  Future<BHAProfile> generateBHAProfile({
    required String userId,
    required TkUserData userData,
    required Map<String, dynamic> bodyScanResults,
    Map<String, dynamic>? faceScanResults,
    Map<String, dynamic>? fingerScanResults,
    List<BHASurveyResponse>? surveyResponses,
  }) async {
    try {
      if (kDebugMode) {
        print('BHA: Generating comprehensive health assessment for user: $userId');
      }

      final List<BHARiskAssessment> riskAssessments = [];
      
      // Body composition assessments
      riskAssessments.addAll(await _analyzeBodyComposition(userData, bodyScanResults));
      
      // Cardiovascular assessments
      riskAssessments.addAll(await _analyzeCardiovascularRisk(userData, bodyScanResults, fingerScanResults));
      
      // Metabolic assessments
      riskAssessments.addAll(await _analyzeMetabolicRisk(userData, bodyScanResults));
      
      // Fitness assessments
      riskAssessments.addAll(await _analyzeFitnessLevel(userData, bodyScanResults));
      
      // Mental health assessments (from surveys if available)
      if (surveyResponses != null) {
        riskAssessments.addAll(await _analyzeMentalHealthRisk(surveyResponses));
      }
      
      // Calculate overall score and risk level
      final overallScore = _calculateOverallScore(riskAssessments);
      final overallRiskLevel = _determineOverallRiskLevel(overallScore, riskAssessments);
      
      // Generate recommendations
      final recommendations = _generateRecommendations(riskAssessments, overallRiskLevel);
      
      // Calculate next assessment date (typically 3-6 months based on risk)
      final nextAssessmentDate = _calculateNextAssessmentDate(overallRiskLevel);
      
      final profile = BHAProfile(
        userId: userId,
        assessmentDate: DateTime.now(),
        overallScore: overallScore,
        overallRiskLevel: overallRiskLevel,
        riskAssessments: riskAssessments,
        recommendations: recommendations,
        nextAssessmentDate: nextAssessmentDate,
      );
      
      if (kDebugMode) {
        print('BHA: Generated profile with ${riskAssessments.length} risk assessments');
        print('BHA: Overall risk level: ${overallRiskLevel.label}');
      }
      
      return profile;
    } catch (e) {
      if (kDebugMode) {
        print('BHA: Error generating profile: $e');
      }
      
      // Return minimal profile on error
      return BHAProfile(
        userId: userId,
        assessmentDate: DateTime.now(),
        overallScore: 0.0,
        overallRiskLevel: BHARiskLevel.unknown,
        riskAssessments: const [],
        recommendations: const ['Unable to complete assessment. Please try again.'],
      );
    }
  }

  /// Analyze body composition risks
  Future<List<BHARiskAssessment>> _analyzeBodyComposition(
    TkUserData userData,
    Map<String, dynamic> bodyScanResults,
  ) async {
    final List<BHARiskAssessment> assessments = [];
    
    try {
      // BMI Assessment
      final double? heightCm = userData.heightInCm;
      final double? weightKg = userData.weightInKg;
      
      if (heightCm != null && weightKg != null && heightCm > 0) {
        final bmi = weightKg / ((heightCm / 100) * (heightCm / 100));
        assessments.add(_createBMIAssessment(bmi));
      }
      
      // Body Fat Percentage Assessment
      final bodyFatPercentage = bodyScanResults['bodyFatPercentage'] as double?;
      if (bodyFatPercentage != null) {
        assessments.add(_createBodyFatAssessment(bodyFatPercentage, userData.biologicalSex == TkBiologicalSex.BS_FEMALE ? 'female' : 'male'));
      }
      
      // Waist-to-Hip Ratio Assessment
      final waistCircumference = bodyScanResults['waistCircumference'] as double?;
      final hipCircumference = bodyScanResults['hipCircumference'] as double?;
      if (waistCircumference != null && hipCircumference != null && hipCircumference > 0) {
        final whr = waistCircumference / hipCircumference;
        assessments.add(_createWaistHipRatioAssessment(whr, userData.biologicalSex == TkBiologicalSex.BS_FEMALE ? 'female' : 'male'));
      }
      
      // Visceral Fat Assessment
      final visceralFatRating = bodyScanResults['visceralFatRating'] as double?;
      if (visceralFatRating != null) {
        assessments.add(_createVisceralFatAssessment(visceralFatRating));
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('BHA: Error in body composition analysis: $e');
      }
    }
    
    return assessments;
  }

  /// Analyze cardiovascular risks
  Future<List<BHARiskAssessment>> _analyzeCardiovascularRisk(
    TkUserData userData,
    Map<String, dynamic> bodyScanResults,
    Map<String, dynamic>? fingerScanResults,
  ) async {
    final List<BHARiskAssessment> assessments = [];
    
    try {
      // Waist-to-Height Ratio (cardiovascular predictor)
      final waistCircumference = bodyScanResults['waistCircumference'] as double?;
      final heightCm = userData.heightInCm;
      
      if (waistCircumference != null && heightCm != null && heightCm > 0) {
        final whr = waistCircumference / heightCm;
        assessments.add(_createWaistHeightRatioAssessment(whr));
      }
      
      // Heart Rate Variability (if available from finger scan)
      if (fingerScanResults != null) {
        final heartRate = fingerScanResults['heartRate'] as double?;
        final hrv = fingerScanResults['heartRateVariability'] as double?;
        
        if (heartRate != null) {
          assessments.add(_createRestingHeartRateAssessment(heartRate, userData.ageInYears));
        }
        
        if (hrv != null) {
          assessments.add(_createHRVAssessment(hrv, userData.ageInYears));
        }
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('BHA: Error in cardiovascular analysis: $e');
      }
    }
    
    return assessments;
  }

  /// Analyze metabolic risks
  Future<List<BHARiskAssessment>> _analyzeMetabolicRisk(
    TkUserData userData,
    Map<String, dynamic> bodyScanResults,
  ) async {
    final List<BHARiskAssessment> assessments = [];
    
    try {
      // Metabolic Age Assessment
      final metabolicAge = bodyScanResults['metabolicAge'] as double?;
      if (metabolicAge != null) {
        assessments.add(_createMetabolicAgeAssessment(metabolicAge, userData.ageInYears));
      }
      
      // Muscle Mass Assessment
      final muscleMass = bodyScanResults['muscleMassKg'] as double?;
      final weightKg = userData.weightInKg;
      
      if (muscleMass != null && weightKg != null && weightKg > 0) {
        final muscleMassPercentage = (muscleMass / weightKg) * 100;
        assessments.add(_createMuscleMassAssessment(muscleMassPercentage, userData.biologicalSex == TkBiologicalSex.BS_FEMALE ? 'female' : 'male', userData.ageInYears));
      }
      
      // Basal Metabolic Rate Assessment
      final bmr = bodyScanResults['basalMetabolicRate'] as double?;
      if (bmr != null) {
        final expectedBMR = _calculateExpectedBMR(userData);
        assessments.add(_createBMRAssessment(bmr, expectedBMR));
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('BHA: Error in metabolic analysis: $e');
      }
    }
    
    return assessments;
  }

  /// Analyze fitness level
  Future<List<BHARiskAssessment>> _analyzeFitnessLevel(
    TkUserData userData,
    Map<String, dynamic> bodyScanResults,
  ) async {
    final List<BHARiskAssessment> assessments = [];
    
    try {
      // Body Water Percentage (hydration indicator)
      final bodyWaterPercentage = bodyScanResults['bodyWaterPercentage'] as double?;
      if (bodyWaterPercentage != null) {
        assessments.add(_createHydrationAssessment(bodyWaterPercentage, userData.biologicalSex == TkBiologicalSex.BS_FEMALE ? 'female' : 'male'));
      }
      
      // Protein Ratio Assessment
      final proteinRatio = bodyScanResults['proteinRatio'] as double?;
      if (proteinRatio != null) {
        assessments.add(_createProteinRatioAssessment(proteinRatio));
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('BHA: Error in fitness analysis: $e');
      }
    }
    
    return assessments;
  }

  /// Analyze mental health risks from survey responses
  Future<List<BHARiskAssessment>> _analyzeMentalHealthRisk(
    List<BHASurveyResponse> surveyResponses,
  ) async {
    final List<BHARiskAssessment> assessments = [];
    
    try {
      // Stress Level Assessment (PHQ-4 or similar)
      final stressResponses = surveyResponses.where((r) => r.questionId.startsWith('stress_')).toList();
      if (stressResponses.isNotEmpty) {
        final stressScore = stressResponses.fold(0.0, (sum, response) => sum + (response.score ?? 0));
        assessments.add(_createStressAssessment(stressScore));
      }
      
      // Sleep Quality Assessment
      final sleepResponses = surveyResponses.where((r) => r.questionId.startsWith('sleep_')).toList();
      if (sleepResponses.isNotEmpty) {
        final sleepScore = sleepResponses.fold(0.0, (sum, response) => sum + (response.score ?? 0));
        assessments.add(_createSleepQualityAssessment(sleepScore));
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('BHA: Error in mental health analysis: $e');
      }
    }
    
    return assessments;
  }

  /// Create BMI risk assessment
  BHARiskAssessment _createBMIAssessment(num bmi) {
    final double bmiFinal = bmi.toDouble();
    late BHARiskLevel riskLevel;
    late String description;
    late List<String> recommendations;
    
    if (bmiFinal < 18.5) {
      riskLevel = BHARiskLevel.moderate;
      description = 'Your BMI indicates you are underweight. This may increase risk of nutritional deficiencies and weakened immune system.';
      recommendations = [
        'Consult with a healthcare provider about healthy weight gain',
        'Focus on nutrient-dense foods',
        'Consider strength training to build muscle mass',
      ];
    } else if (bmiFinal < 25.0) {
      riskLevel = BHARiskLevel.low;
      description = 'Your BMI is in the healthy range. Continue maintaining your current weight through balanced nutrition and regular exercise.';
      recommendations = [
        'Maintain current healthy lifestyle',
        'Continue regular physical activity',
        'Focus on balanced nutrition',
      ];
    } else if (bmiFinal < 30.0) {
      riskLevel = BHARiskLevel.moderate;
      description = 'Your BMI indicates you are overweight. This may increase risk of cardiovascular disease and diabetes.';
      recommendations = [
        'Aim for gradual weight loss of 1-2 pounds per week',
        'Increase physical activity to 150+ minutes per week',
        'Focus on portion control and balanced meals',
      ];
    } else {
      riskLevel = BHARiskLevel.high;
      description = 'Your BMI indicates obesity. This significantly increases risk of cardiovascular disease, diabetes, and other health conditions.';
      recommendations = [
        'Consult with healthcare provider for weight management plan',
        'Consider structured weight loss program',
        'Focus on sustainable lifestyle changes',
        'Regular monitoring of blood pressure and glucose levels',
      ];
    }
    
    return BHARiskAssessment(
      category: BHARiskCategory.bodyComposition,
      riskLevel: riskLevel,
      score: math.max(0, math.min(100, 100 - (bmiFinal - 22.5).abs() * 5)),
      title: 'Body Mass Index',
      description: description,
      recommendations: recommendations,
      metrics: {'bmi': bmiFinal.toStringAsFixed(1)},
    );
  }

  /// Create body fat percentage assessment
  BHARiskAssessment _createBodyFatAssessment(double bodyFatPercentage, String? gender) {
    late BHARiskLevel riskLevel;
    late String description;
    
    // Gender-specific body fat ranges
    final bool isFemale = gender?.toLowerCase() == 'female';
    
    if (isFemale) {
      if (bodyFatPercentage < 16) {
        riskLevel = BHARiskLevel.moderate;
        description = 'Your body fat percentage is below optimal range, which may affect hormone production and overall health.';
      } else if (bodyFatPercentage <= 24) {
        riskLevel = BHARiskLevel.low;
        description = 'Your body fat percentage is in the healthy range for women.';
      } else if (bodyFatPercentage <= 31) {
        riskLevel = BHARiskLevel.moderate;
        description = 'Your body fat percentage is slightly elevated, which may increase health risks.';
      } else {
        riskLevel = BHARiskLevel.high;
        description = 'Your body fat percentage is significantly elevated, increasing risk of metabolic disorders.';
      }
    } else {
      if (bodyFatPercentage < 8) {
        riskLevel = BHARiskLevel.moderate;
        description = 'Your body fat percentage is below optimal range, which may affect hormone production and overall health.';
      } else if (bodyFatPercentage <= 19) {
        riskLevel = BHARiskLevel.low;
        description = 'Your body fat percentage is in the healthy range for men.';
      } else if (bodyFatPercentage <= 25) {
        riskLevel = BHARiskLevel.moderate;
        description = 'Your body fat percentage is slightly elevated, which may increase health risks.';
      } else {
        riskLevel = BHARiskLevel.high;
        description = 'Your body fat percentage is significantly elevated, increasing risk of metabolic disorders.';
      }
    }
    
    final score = riskLevel == BHARiskLevel.low ? 85.0 : 
                  riskLevel == BHARiskLevel.moderate ? 65.0 : 35.0;
    
    return BHARiskAssessment(
      category: BHARiskCategory.bodyComposition,
      riskLevel: riskLevel,
      score: score.toDouble(),
      title: 'Body Fat Percentage',
      description: description,
      recommendations: _getBodyFatRecommendations(riskLevel),
      metrics: {'bodyFatPercentage': bodyFatPercentage.toStringAsFixed(1)},
    );
  }

  /// Create waist-to-hip ratio assessment
  BHARiskAssessment _createWaistHipRatioAssessment(num whr, String? gender) {
    final double whrFinal = whr.toDouble();
    late BHARiskLevel riskLevel;
    late String description;
    
    final bool isFemale = gender?.toLowerCase() == 'female';
    final double highRiskThreshold = isFemale ? 0.85 : 0.90;
    final double moderateRiskThreshold = isFemale ? 0.80 : 0.85;
    
    if (whrFinal < moderateRiskThreshold) {
      riskLevel = BHARiskLevel.low;
      description = 'Your waist-to-hip ratio indicates low risk for cardiovascular disease and metabolic disorders.';
    } else if (whrFinal < highRiskThreshold) {
      riskLevel = BHARiskLevel.moderate;
      description = 'Your waist-to-hip ratio indicates moderate risk for cardiovascular disease and metabolic disorders.';
    } else {
      riskLevel = BHARiskLevel.high;
      description = 'Your waist-to-hip ratio indicates high risk for cardiovascular disease and metabolic disorders.';
    }
    
    final score = riskLevel == BHARiskLevel.low ? 85.0 : 
                  riskLevel == BHARiskLevel.moderate ? 60.0 : 30.0;
    
    return BHARiskAssessment(
      category: BHARiskCategory.cardiovascular,
      riskLevel: riskLevel,
      score: score.toDouble(),
      title: 'Waist-to-Hip Ratio',
      description: description,
      recommendations: _getWaistHipRatioRecommendations(riskLevel),
      metrics: {'waistHipRatio': whrFinal.toStringAsFixed(2)},
    );
  }

  /// Create visceral fat assessment
  BHARiskAssessment _createVisceralFatAssessment(num visceralFatRating) {
    final double rating = visceralFatRating.toDouble();
    late BHARiskLevel riskLevel;
    late String description;
    
    if (rating < 10) {
      riskLevel = BHARiskLevel.low;
      description = 'Your visceral fat level is in the healthy range.';
    } else if (rating < 15) {
      riskLevel = BHARiskLevel.moderate;
      description = 'Your visceral fat level is slightly elevated, which may increase health risks.';
    } else {
      riskLevel = BHARiskLevel.high;
      description = 'Your visceral fat level is significantly elevated, increasing risk of metabolic and cardiovascular diseases.';
    }
    
    final score = math.max(0, 100 - rating * 6);
    
    return BHARiskAssessment(
      category: BHARiskCategory.bodyComposition,
      riskLevel: riskLevel,
      score: score.toDouble(),
      title: 'Visceral Fat Level',
      description: description,
      recommendations: _getVisceralFatRecommendations(riskLevel),
      metrics: {'visceralFatRating': rating.toStringAsFixed(0)},
    );
  }

  /// Create waist-to-height ratio assessment for cardiovascular risk
  BHARiskAssessment _createWaistHeightRatioAssessment(num whr) {
    final double ratio = whr.toDouble();
    late BHARiskLevel riskLevel;
    late String description;
    
    if (ratio < 0.43) {
      riskLevel = BHARiskLevel.low;
      description = 'Your waist-to-height ratio indicates low cardiovascular risk.';
    } else if (ratio < 0.53) {
      riskLevel = BHARiskLevel.moderate;
      description = 'Your waist-to-height ratio indicates moderate cardiovascular risk.';
    } else {
      riskLevel = BHARiskLevel.high;
      description = 'Your waist-to-height ratio indicates high cardiovascular risk.';
    }
    
    final score = math.max(0, 100 - (ratio - 0.43) * 200);
    
    return BHARiskAssessment(
      category: BHARiskCategory.cardiovascular,
      riskLevel: riskLevel,
      score: score.toDouble(),
      title: 'Waist-to-Height Ratio',
      description: description,
      recommendations: _getCardiovascularRecommendations(riskLevel),
      metrics: {'waistHeightRatio': ratio.toStringAsFixed(2)},
    );
  }

  /// Create resting heart rate assessment
  BHARiskAssessment _createRestingHeartRateAssessment(num heartRate, int? age) {
    final double rate = heartRate.toDouble();
    late BHARiskLevel riskLevel;
    late String description;
    
    if (rate < 60) {
      riskLevel = BHARiskLevel.low;
      description = 'Your resting heart rate indicates excellent cardiovascular fitness.';
    } else if (rate <= 80) {
      riskLevel = BHARiskLevel.low;
      description = 'Your resting heart rate is in the normal range.';
    } else if (rate <= 90) {
      riskLevel = BHARiskLevel.moderate;
      description = 'Your resting heart rate is slightly elevated, which may indicate cardiovascular stress.';
    } else {
      riskLevel = BHARiskLevel.high;
      description = 'Your resting heart rate is elevated, which may indicate cardiovascular risk.';
    }
    
    final score = math.max(0, 100 - (rate - 60) * 2);
    
    return BHARiskAssessment(
      category: BHARiskCategory.cardiovascular,
      riskLevel: riskLevel,
      score: score.toDouble(),
      title: 'Resting Heart Rate',
      description: description,
      recommendations: _getHeartRateRecommendations(riskLevel),
      metrics: {'restingHeartRate': rate.toStringAsFixed(0)},
    );
  }

  /// Create HRV assessment
  BHARiskAssessment _createHRVAssessment(num hrv, int? age) {
    final double hrvFinal = hrv.toDouble();
    late BHARiskLevel riskLevel;
    late String description;
    
    // Age-adjusted HRV ranges (simplified)
    final double goodHRV = age != null && age > 50 ? 25.0 : 35.0;
    final double fairHRV = age != null && age > 50 ? 15.0 : 25.0;
    
    if (hrvFinal >= goodHRV) {
      riskLevel = BHARiskLevel.low;
      description = 'Your heart rate variability indicates good cardiovascular health and stress resilience.';
    } else if (hrvFinal >= fairHRV) {
      riskLevel = BHARiskLevel.moderate;
      description = 'Your heart rate variability is fair, suggesting moderate cardiovascular health.';
    } else {
      riskLevel = BHARiskLevel.high;
      description = 'Your heart rate variability is low, which may indicate cardiovascular stress or poor recovery.';
    }
    
    final score = math.min(100, hrvFinal * 2);
    
    return BHARiskAssessment(
      category: BHARiskCategory.cardiovascular,
      riskLevel: riskLevel,
      score: score.toDouble(),
      title: 'Heart Rate Variability',
      description: description,
      recommendations: _getHRVRecommendations(riskLevel),
      metrics: {'heartRateVariability': hrvFinal.toStringAsFixed(1)},
    );
  }

  /// Create metabolic age assessment
  BHARiskAssessment _createMetabolicAgeAssessment(double metabolicAge, int? chronologicalAge) {
    if (chronologicalAge == null) {
      return BHARiskAssessment(
        category: BHARiskCategory.metabolic,
        riskLevel: BHARiskLevel.unknown,
        score: 0.0,
        title: 'Metabolic Age',
        description: 'Unable to assess metabolic age without chronological age.',
        recommendations: const [],
        metrics: {'metabolicAge': metabolicAge.toStringAsFixed(0)},
      );
    }
    
    final double ageDifference = metabolicAge - chronologicalAge;
    late BHARiskLevel riskLevel;
    late String description;
    
    if (ageDifference < -5) {
      riskLevel = BHARiskLevel.low;
      description = 'Your metabolic age is significantly lower than your chronological age, indicating excellent metabolic health.';
    } else if (ageDifference < 0) {
      riskLevel = BHARiskLevel.low;
      description = 'Your metabolic age is lower than your chronological age, indicating good metabolic health.';
    } else if (ageDifference < 5) {
      riskLevel = BHARiskLevel.moderate;
      description = 'Your metabolic age is close to your chronological age, indicating average metabolic health.';
    } else {
      riskLevel = BHARiskLevel.high;
      description = 'Your metabolic age is higher than your chronological age, indicating poor metabolic health.';
    }
    
    final score = math.max(0, 100 - ageDifference * 5);
    
    return BHARiskAssessment(
      category: BHARiskCategory.metabolic,
      riskLevel: riskLevel,
      score: score.toDouble(),
      title: 'Metabolic Age',
      description: description,
      recommendations: _getMetabolicAgeRecommendations(riskLevel),
      metrics: {
        'metabolicAge': metabolicAge.toStringAsFixed(0),
        'chronologicalAge': chronologicalAge.toString(),
        'ageDifference': ageDifference.toStringAsFixed(1),
      },
    );
  }

  /// Create muscle mass assessment
  BHARiskAssessment _createMuscleMassAssessment(double muscleMassPercentage, String? gender, int? age) {
    late BHARiskLevel riskLevel;
    late String description;
    
    // Simplified muscle mass ranges by gender and age
    final bool isFemale = gender?.toLowerCase() == 'female';
    final double optimalMuscle = isFemale ? 36.0 : 42.0;
    final double lowMuscle = isFemale ? 30.0 : 36.0;
    
    if (muscleMassPercentage >= optimalMuscle) {
      riskLevel = BHARiskLevel.low;
      description = 'Your muscle mass percentage is excellent, supporting healthy metabolism and bone density.';
    } else if (muscleMassPercentage >= lowMuscle) {
      riskLevel = BHARiskLevel.moderate;
      description = 'Your muscle mass percentage is fair but could be improved for better metabolic health.';
    } else {
      riskLevel = BHARiskLevel.high;
      description = 'Your muscle mass percentage is low, which may increase risk of metabolic disorders and bone loss.';
    }
    
    final score = math.min(100, muscleMassPercentage * 2);
    
    return BHARiskAssessment(
      category: BHARiskCategory.fitness,
      riskLevel: riskLevel,
      score: score.toDouble(),
      title: 'Muscle Mass Percentage',
      description: description,
      recommendations: _getMuscleMassRecommendations(riskLevel),
      metrics: {'muscleMassPercentage': muscleMassPercentage.toStringAsFixed(1)},
    );
  }

  /// Create BMR assessment
  BHARiskAssessment _createBMRAssessment(double actualBMR, double expectedBMR) {
    final double ratio = actualBMR / expectedBMR;
    late BHARiskLevel riskLevel;
    late String description;
    
    if (ratio >= 1.05) {
      riskLevel = BHARiskLevel.low;
      description = 'Your metabolic rate is higher than expected, indicating good metabolic health.';
    } else if (ratio >= 0.95) {
      riskLevel = BHARiskLevel.low;
      description = 'Your metabolic rate is normal for your age, gender, and body composition.';
    } else if (ratio >= 0.85) {
      riskLevel = BHARiskLevel.moderate;
      description = 'Your metabolic rate is slightly below expected, which may affect weight management.';
    } else {
      riskLevel = BHARiskLevel.high;
      description = 'Your metabolic rate is significantly below expected, indicating metabolic dysfunction.';
    }
    
    final score = ratio * 85;
    
    return BHARiskAssessment(
      category: BHARiskCategory.metabolic,
      riskLevel: riskLevel,
      score: score.toDouble(),
      title: 'Basal Metabolic Rate',
      description: description,
      recommendations: _getBMRRecommendations(riskLevel),
      metrics: {
        'actualBMR': actualBMR.toStringAsFixed(0),
        'expectedBMR': expectedBMR.toStringAsFixed(0),
        'ratio': ratio.toStringAsFixed(2),
      },
    );
  }

  /// Create hydration assessment
  BHARiskAssessment _createHydrationAssessment(double bodyWaterPercentage, String? gender) {
    late BHARiskLevel riskLevel;
    late String description;
    
    final bool isFemale = gender?.toLowerCase() == 'female';
    final double optimalWater = isFemale ? 55.0 : 60.0;
    final double lowWater = isFemale ? 45.0 : 50.0;
    
    if (bodyWaterPercentage >= optimalWater) {
      riskLevel = BHARiskLevel.low;
      description = 'Your body water percentage indicates optimal hydration levels.';
    } else if (bodyWaterPercentage >= lowWater) {
      riskLevel = BHARiskLevel.moderate;
      description = 'Your body water percentage indicates mild dehydration.';
    } else {
      riskLevel = BHARiskLevel.high;
      description = 'Your body water percentage indicates significant dehydration, which may affect performance and health.';
    }
    
    final score = bodyWaterPercentage * 1.5;
    
    return BHARiskAssessment(
      category: BHARiskCategory.fitness,
      riskLevel: riskLevel,
      score: score.toDouble(),
      title: 'Hydration Level',
      description: description,
      recommendations: _getHydrationRecommendations(riskLevel),
      metrics: {'bodyWaterPercentage': bodyWaterPercentage.toStringAsFixed(1)},
    );
  }

  /// Create protein ratio assessment
  BHARiskAssessment _createProteinRatioAssessment(double proteinRatio) {
    late BHARiskLevel riskLevel;
    late String description;
    
    if (proteinRatio >= 18.0) {
      riskLevel = BHARiskLevel.low;
      description = 'Your protein ratio indicates adequate muscle protein synthesis capacity.';
    } else if (proteinRatio >= 16.0) {
      riskLevel = BHARiskLevel.moderate;
      description = 'Your protein ratio is fair but could be improved with proper nutrition and exercise.';
    } else {
      riskLevel = BHARiskLevel.high;
      description = 'Your protein ratio is low, which may indicate muscle protein deficiency.';
    }
    
    final score = proteinRatio * 5;
    
    return BHARiskAssessment(
      category: BHARiskCategory.fitness,
      riskLevel: riskLevel,
      score: score.toDouble(),
      title: 'Protein Ratio',
      description: description,
      recommendations: _getProteinRecommendations(riskLevel),
      metrics: {'proteinRatio': proteinRatio.toStringAsFixed(1)},
    );
  }

  /// Create stress assessment from survey data
  BHARiskAssessment _createStressAssessment(double stressScore) {
    late BHARiskLevel riskLevel;
    late String description;
    
    if (stressScore < 3) {
      riskLevel = BHARiskLevel.low;
      description = 'Your stress level is low, indicating good mental health resilience.';
    } else if (stressScore < 6) {
      riskLevel = BHARiskLevel.moderate;
      description = 'Your stress level is moderate. Consider stress management techniques.';
    } else {
      riskLevel = BHARiskLevel.high;
      description = 'Your stress level is high, which may affect physical and mental health.';
    }
    
    final score = math.max(0, 100 - stressScore * 10);
    
    return BHARiskAssessment(
      category: BHARiskCategory.mentalHealth,
      riskLevel: riskLevel,
      score: score.toDouble(),
      title: 'Stress Level',
      description: description,
      recommendations: _getStressRecommendations(riskLevel),
      metrics: {'stressScore': stressScore.toStringAsFixed(1)},
    );
  }

  /// Create sleep quality assessment
  BHARiskAssessment _createSleepQualityAssessment(double sleepScore) {
    late BHARiskLevel riskLevel;
    late String description;
    
    if (sleepScore >= 8) {
      riskLevel = BHARiskLevel.low;
      description = 'Your sleep quality is excellent, supporting overall health and recovery.';
    } else if (sleepScore >= 6) {
      riskLevel = BHARiskLevel.moderate;
      description = 'Your sleep quality is fair but could be improved for better health outcomes.';
    } else {
      riskLevel = BHARiskLevel.high;
      description = 'Your sleep quality is poor, which may significantly impact physical and mental health.';
    }
    
    final score = sleepScore * 12.5;
    
    return BHARiskAssessment(
      category: BHARiskCategory.mentalHealth,
      riskLevel: riskLevel,
      score: score.toDouble(),
      title: 'Sleep Quality',
      description: description,
      recommendations: _getSleepRecommendations(riskLevel),
      metrics: {'sleepScore': sleepScore.toStringAsFixed(1)},
    );
  }

  /// Calculate expected BMR using Mifflin-St Jeor equation
  double _calculateExpectedBMR(TkUserData userData) {
    final weightKg = userData.weightInKg ?? 70.0;
    final heightCm = userData.heightInCm ?? 170.0;
    final age = userData.ageInYears ?? 30;
    final isFemale = userData.biologicalSex == TkBiologicalSex.BS_FEMALE;
    
    if (isFemale) {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
    } else {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    }
  }

  /// Calculate overall score from individual assessments
  double _calculateOverallScore(List<BHARiskAssessment> assessments) {
    if (assessments.isEmpty) return 0.0;
    
    final totalScore = assessments.fold(0.0, (sum, assessment) => sum + assessment.score);
    return totalScore / assessments.length;
  }

  /// Determine overall risk level
  BHARiskLevel _determineOverallRiskLevel(double overallScore, List<BHARiskAssessment> assessments) {
    // Check for any high-risk assessments
    final hasHighRisk = assessments.any((a) => a.riskLevel == BHARiskLevel.high);
    if (hasHighRisk) return BHARiskLevel.high;
    
    // Check for multiple moderate-risk assessments
    final moderateRiskCount = assessments.where((a) => a.riskLevel == BHARiskLevel.moderate).length;
    if (moderateRiskCount >= 3) return BHARiskLevel.high;
    if (moderateRiskCount >= 1) return BHARiskLevel.moderate;
    
    // Use overall score
    if (overallScore >= 75) return BHARiskLevel.low;
    if (overallScore >= 50) return BHARiskLevel.moderate;
    return BHARiskLevel.high;
  }

  /// Generate personalized recommendations
  List<String> _generateRecommendations(List<BHARiskAssessment> assessments, BHARiskLevel overallRiskLevel) {
    final Set<String> recommendations = {};
    
    // Add assessment-specific recommendations
    for (final assessment in assessments) {
      recommendations.addAll(assessment.recommendations);
    }
    
    // Add general recommendations based on overall risk
    switch (overallRiskLevel) {
      case BHARiskLevel.high:
        recommendations.add('Consult with healthcare provider for comprehensive evaluation');
        recommendations.add('Consider working with registered dietitian for meal planning');
        recommendations.add('Start with gentle exercise program and gradually increase intensity');
        break;
      case BHARiskLevel.moderate:
        recommendations.add('Focus on lifestyle modifications for gradual improvement');
        recommendations.add('Monitor progress with regular health assessments');
        break;
      case BHARiskLevel.low:
        recommendations.add('Continue current healthy lifestyle practices');
        recommendations.add('Maintain regular exercise and balanced nutrition');
        break;
      case BHARiskLevel.unknown:
        recommendations.add('Complete additional health assessments for better evaluation');
        break;
    }
    
    return recommendations.take(8).toList(); // Limit to top 8 recommendations
  }

  /// Calculate next assessment date
  DateTime _calculateNextAssessmentDate(BHARiskLevel overallRiskLevel) {
    final now = DateTime.now();
    
    switch (overallRiskLevel) {
      case BHARiskLevel.high:
        return now.add(const Duration(days: 90)); // 3 months
      case BHARiskLevel.moderate:
        return now.add(const Duration(days: 120)); // 4 months
      case BHARiskLevel.low:
        return now.add(const Duration(days: 180)); // 6 months
      case BHARiskLevel.unknown:
        return now.add(const Duration(days: 30)); // 1 month
    }
  }

  // Recommendation helper methods
  List<String> _getBodyFatRecommendations(BHARiskLevel riskLevel) {
    switch (riskLevel) {
      case BHARiskLevel.high:
        return [
          'Focus on creating caloric deficit through diet and exercise',
          'Include both cardio and strength training in your routine',
          'Consider working with fitness professional',
        ];
      case BHARiskLevel.moderate:
        return [
          'Increase physical activity to 150+ minutes per week',
          'Focus on strength training to build lean muscle',
          'Monitor portion sizes and food quality',
        ];
      default:
        return [
          'Maintain current exercise routine',
          'Continue balanced nutrition approach',
        ];
    }
  }

  List<String> _getWaistHipRatioRecommendations(BHARiskLevel riskLevel) {
    switch (riskLevel) {
      case BHARiskLevel.high:
        return [
          'Focus on reducing abdominal fat through targeted exercises',
          'Limit processed foods and added sugars',
          'Include high-intensity interval training (HIIT)',
        ];
      case BHARiskLevel.moderate:
        return [
          'Emphasize core strengthening exercises',
          'Reduce refined carbohydrates in diet',
          'Increase fiber intake for better satiety',
        ];
      default:
        return [
          'Continue current exercise routine',
          'Maintain healthy dietary patterns',
        ];
    }
  }

  List<String> _getVisceralFatRecommendations(BHARiskLevel riskLevel) {
    switch (riskLevel) {
      case BHARiskLevel.high:
        return [
          'Prioritize aerobic exercise to reduce visceral fat',
          'Limit alcohol consumption',
          'Focus on anti-inflammatory foods',
          'Manage stress levels through relaxation techniques',
        ];
      case BHARiskLevel.moderate:
        return [
          'Include regular cardiovascular exercise',
          'Reduce processed food intake',
          'Increase omega-3 fatty acids in diet',
        ];
      default:
        return [
          'Maintain current healthy lifestyle',
          'Continue regular physical activity',
        ];
    }
  }

  List<String> _getCardiovascularRecommendations(BHARiskLevel riskLevel) {
    switch (riskLevel) {
      case BHARiskLevel.high:
        return [
          'Consult cardiologist for comprehensive evaluation',
          'Monitor blood pressure regularly',
          'Follow DASH diet principles',
          'Aim for 30+ minutes of moderate exercise daily',
        ];
      case BHARiskLevel.moderate:
        return [
          'Increase cardiovascular exercise frequency',
          'Reduce sodium intake',
          'Include heart-healthy foods in diet',
        ];
      default:
        return [
          'Continue heart-healthy lifestyle practices',
          'Maintain regular exercise routine',
        ];
    }
  }

  List<String> _getHeartRateRecommendations(BHARiskLevel riskLevel) {
    switch (riskLevel) {
      case BHARiskLevel.high:
        return [
          'Consult healthcare provider about elevated heart rate',
          'Practice stress reduction techniques',
          'Limit caffeine intake',
          'Start gentle exercise program',
        ];
      case BHARiskLevel.moderate:
        return [
          'Incorporate regular cardiovascular training',
          'Practice deep breathing exercises',
          'Monitor caffeine and stimulant intake',
        ];
      default:
        return [
          'Continue current fitness routine',
          'Maintain good sleep hygiene',
        ];
    }
  }

  List<String> _getHRVRecommendations(BHARiskLevel riskLevel) {
    switch (riskLevel) {
      case BHARiskLevel.high:
        return [
          'Focus on recovery and stress management',
          'Ensure adequate sleep (7-9 hours)',
          'Practice meditation or mindfulness',
          'Avoid overtraining',
        ];
      case BHARiskLevel.moderate:
        return [
          'Implement stress reduction techniques',
          'Optimize sleep quality and duration',
          'Balance exercise with recovery',
        ];
      default:
        return [
          'Continue current recovery practices',
          'Maintain consistent sleep schedule',
        ];
    }
  }

  List<String> _getMetabolicAgeRecommendations(BHARiskLevel riskLevel) {
    switch (riskLevel) {
      case BHARiskLevel.high:
        return [
          'Focus on building lean muscle mass',
          'Increase daily physical activity',
          'Optimize protein intake for age',
          'Consider metabolic testing',
        ];
      case BHARiskLevel.moderate:
        return [
          'Include strength training 2-3x per week',
          'Increase daily movement and activity',
          'Focus on nutrient-dense foods',
        ];
      default:
        return [
          'Maintain current exercise routine',
          'Continue healthy dietary patterns',
        ];
    }
  }

  List<String> _getMuscleMassRecommendations(BHARiskLevel riskLevel) {
    switch (riskLevel) {
      case BHARiskLevel.high:
        return [
          'Prioritize resistance training 3-4x per week',
          'Increase protein intake to 1.2-1.6g per kg body weight',
          'Consider working with strength training professional',
          'Ensure adequate recovery between sessions',
        ];
      case BHARiskLevel.moderate:
        return [
          'Add 2-3 strength training sessions per week',
          'Focus on compound movements',
          'Optimize post-workout nutrition',
        ];
      default:
        return [
          'Continue current strength training routine',
          'Maintain adequate protein intake',
        ];
    }
  }

  List<String> _getBMRRecommendations(BHARiskLevel riskLevel) {
    switch (riskLevel) {
      case BHARiskLevel.high:
        return [
          'Consider thyroid function testing',
          'Focus on building metabolically active muscle tissue',
          'Avoid extreme calorie restriction',
          'Include metabolism-boosting foods',
        ];
      case BHARiskLevel.moderate:
        return [
          'Increase daily physical activity',
          'Build muscle through resistance training',
          'Eat regular, balanced meals',
        ];
      default:
        return [
          'Maintain current activity level',
          'Continue balanced nutrition approach',
        ];
    }
  }

  List<String> _getHydrationRecommendations(BHARiskLevel riskLevel) {
    switch (riskLevel) {
      case BHARiskLevel.high:
        return [
          'Increase daily water intake significantly',
          'Monitor urine color as hydration indicator',
          'Include electrolyte-rich foods',
          'Limit dehydrating beverages',
        ];
      case BHARiskLevel.moderate:
        return [
          'Aim for 8-10 glasses of water daily',
          'Increase intake during exercise',
          'Include water-rich foods in diet',
        ];
      default:
        return [
          'Maintain current hydration habits',
          'Continue drinking water throughout day',
        ];
    }
  }

  List<String> _getProteinRecommendations(BHARiskLevel riskLevel) {
    switch (riskLevel) {
      case BHARiskLevel.high:
        return [
          'Increase protein intake to support muscle synthesis',
          'Include complete proteins at each meal',
          'Consider protein timing around workouts',
          'Focus on leucine-rich protein sources',
        ];
      case BHARiskLevel.moderate:
        return [
          'Add protein-rich snacks between meals',
          'Include variety of protein sources',
          'Combine with strength training',
        ];
      default:
        return [
          'Maintain current protein intake',
          'Continue balanced nutrition approach',
        ];
    }
  }

  List<String> _getStressRecommendations(BHARiskLevel riskLevel) {
    switch (riskLevel) {
      case BHARiskLevel.high:
        return [
          'Consider counseling or therapy for stress management',
          'Practice daily mindfulness or meditation',
          'Implement stress reduction techniques',
          'Ensure adequate sleep and recovery',
        ];
      case BHARiskLevel.moderate:
        return [
          'Practice regular stress management techniques',
          'Include relaxation activities in daily routine',
          'Consider yoga or meditation',
        ];
      default:
        return [
          'Continue current stress management practices',
          'Maintain work-life balance',
        ];
    }
  }

  List<String> _getSleepRecommendations(BHARiskLevel riskLevel) {
    switch (riskLevel) {
      case BHARiskLevel.high:
        return [
          'Consult healthcare provider about sleep issues',
          'Establish consistent sleep schedule',
          'Create optimal sleep environment',
          'Limit screen time before bed',
        ];
      case BHARiskLevel.moderate:
        return [
          'Improve sleep hygiene practices',
          'Aim for 7-9 hours of sleep nightly',
          'Create relaxing bedtime routine',
        ];
      default:
        return [
          'Maintain current sleep schedule',
          'Continue good sleep hygiene practices',
        ];
    }
  }
}