import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/services/logging_service.dart';

/// Service for AWS Lambda health assessment API
class LambdaService {
  // AWS Lambda endpoint - direct URL with proper path
  static const String _baseUrl = 'https://o5t5ewcghf.execute-api.ap-southeast-2.amazonaws.com/bha/';
  static const Duration _timeout = Duration(seconds: 30);
  
  /// Submit face scan results to Lambda for health assessment
  static Future<HealthAssessmentResult> submitForHealthAssessment({
    required Map<String, dynamic> scanResults,
    required Map<String, dynamic> userData,
  }) async {
    try {
      LoggingService.info(
        'Submitting to Lambda API',
        tag: 'LambdaService',
        context: {'endpoint': _baseUrl},
      );

      // Prepare request data
      final requestData = _prepareScanData(scanResults, userData);
      LoggingService.debug(
        'Lambda request data prepared',
        tag: 'LambdaService',
        context: {'data': jsonEncode(requestData)},
      );

      // Make API call
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestData),
          )
          .timeout(_timeout);

      LoggingService.debug(
        'Lambda response received',
        tag: 'LambdaService',
        context: {
          'statusCode': response.statusCode,
          'headers': response.headers.toString(),
          'body': response.body,
        },
      );

      // Check for CORS or other errors
      if (response.statusCode == 403) {
        LoggingService.warning(
          'CORS or authentication error. Check Lambda configuration.',
          tag: 'LambdaService',
          context: {'statusCode': 403},
        );
      }

      if (response.statusCode != 200) {
        throw Exception('Lambda request failed: ${response.statusCode} - ${response.body}');
      }

      final result = jsonDecode(response.body);

      // Check for error response
      if (result['errorType'] != null || result['errorMessage'] != null) {
        throw Exception('Lambda error: ${result['errorMessage'] ?? result['errorType']}');
      }

      LoggingService.success('Lambda response parsed successfully', tag: 'LambdaService');
      return _processLambdaResponse(scanResults, result);
    } catch (e, stackTrace) {
      LoggingService.error(
        'Error submitting to Lambda',
        error: e,
        stackTrace: stackTrace,
        tag: 'LambdaService',
      );
      // Return basic results if Lambda fails
      return HealthAssessmentResult.fromScanOnly(scanResults);
    }
  }
  
  /// Prepare scan data for Lambda submission
  static Map<String, dynamic> _prepareScanData(
    Map<String, dynamic> scanResults,
    Map<String, dynamic> userData,
  ) {
    // Calculate age from DOB or use provided age
    DateTime? birthDate;
    if (userData['dateOfBirth'] != null) {
      if (userData['dateOfBirth'] is DateTime) {
        birthDate = userData['dateOfBirth'];
      } else {
        birthDate = DateTime.tryParse(userData['dateOfBirth'].toString());
      }
    }
    
    final ageValue = userData['age'] ?? 30;
    final age = birthDate != null 
        ? DateTime.now().year - birthDate.year 
        : (ageValue is int ? ageValue : int.tryParse(ageValue.toString()) ?? 30);
    
    // Convert height to cm if needed
    double height = userData['height']?.toDouble() ?? 170.0;
    if (userData['heightUnit'] == 'ft' && userData['heightFeet'] != null) {
      final feet = (userData['heightFeet'] ?? 0).toDouble();
      final inches = (userData['heightInches'] ?? 0).toDouble();
      height = (feet * 30.48) + (inches * 2.54);
    }
    height = height.clamp(100, 250);
    
    // Convert weight to kg if needed
    double weight = userData['weight']?.toDouble() ?? 70.0;
    if (userData['weightUnit'] == 'lbs') {
      weight = weight * 0.453592;
    }
    weight = weight.clamp(30, 250);
    
    // Ensure vital signs are within valid ranges
    final heartRate = (scanResults['heartRate'] ?? 70).clamp(20, 120);
    final systolicBP = (scanResults['systolicBP'] ?? 120).clamp(70, 200);
    final diastolicBP = (scanResults['diastolicBP'] ?? 80).clamp(40, 130);
    final respiratoryRate = (scanResults['respiratoryRate'] ?? 16).clamp(8, 40);
    final oxygenSaturation = (scanResults['oxygenSaturation'] ?? 98).clamp(70, 100);
    
    return {
      // User demographics
      'enum_ent_sex': userData['gender']?.toString().toLowerCase() ?? 'male',
      'date_ent_dob': birthDate?.toIso8601String().split('T')[0] ?? 
                      DateTime(DateTime.now().year - age, 1, 1).toIso8601String().split('T')[0],
      'date_ent_assessment': DateTime.now().toIso8601String().split('T')[0],
      'cm_ent_height': height.round(),
      'kg_ent_weight': weight.round(),
      
      // Activity and health info
      'enum_ent_activityLevel': userData['exerciseLevel'] ?? 'inactive',
      'enum_ent_chronicMedication': userData['chronicMedication'] ?? 'none',
      'enum_ent_smoker': userData['smokingStatus'] ?? 'never',
      'bool_ent_bpMedication': userData['takingBPMedication'] == 'yes',
      
      // Vital signs from scan
      'mmHg_ent_systolicBP': systolicBP.round(),
      'mmHg_ent_diastolicBP': diastolicBP.round(),
      'bpm_ent_restingHeartRate': heartRate.round(),
      
      // Additional metrics
      'int_raw_rr': respiratoryRate.round(),
      'int_raw_oxygen': oxygenSaturation.round(),
      'flt_raw_ibi': scanResults['ibi'] ?? 800,
      'flt_raw_sdnn': scanResults['sdnn'] ?? scanResults['heartRateVariability'] ?? 50,
      'flt_raw_rmssd': scanResults['rmssd'] ?? 40,
      'flt_raw_stressIndex': _calculateStressIndex(scanResults['stressLevel']),
    };
  }
  
  /// Calculate stress index from stress level
  static double _calculateStressIndex(dynamic stressLevel) {
    if (stressLevel is double) {
      return (stressLevel * 10).clamp(0, 10);
    }
    
    switch (stressLevel?.toString().toLowerCase()) {
      case 'low':
        return 2.0;
      case 'normal':
        return 5.0;
      case 'moderate':
        return 7.0;
      case 'elevated':
        return 8.0;
      case 'high':
        return 9.0;
      default:
        return 5.0;
    }
  }
  
  /// Normalize stress level to a string value
  static String _normalizeStressLevel(dynamic stressLevel) {
    if (stressLevel == null) return 'normal';
    
    // If it's already a string, return it
    if (stressLevel is String) return stressLevel;
    
    // If it's a double (0.0 - 1.0), convert to string
    if (stressLevel is double) {
      if (stressLevel <= 0.3) return 'low';
      if (stressLevel <= 0.6) return 'normal';
      if (stressLevel <= 0.8) return 'elevated';
      return 'high';
    }
    
    // If it's an int, treat it similarly
    if (stressLevel is int) {
      if (stressLevel <= 3) return 'low';
      if (stressLevel <= 6) return 'normal';
      if (stressLevel <= 8) return 'elevated';
      return 'high';
    }
    
    return 'normal';
  }
  
  /// Process Lambda response and merge with scan results
  static HealthAssessmentResult _processLambdaResponse(
    Map<String, dynamic> scanResults,
    Map<String, dynamic> lambdaResponse,
  ) {
    final outputs = lambdaResponse['outputs'] ?? {};
    final risks = lambdaResponse['risks'] ?? {};
    
    // Helper function to safely convert to double
    double? toDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }
    
    // Helper function to safely convert to int
    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) return int.tryParse(value);
      return null;
    }
    
    // Calculate health score based on risk factors
    final riskValues = risks.values.toList();
    final lowCount = riskValues.where((r) => r == 'low').length;
    final totalCount = riskValues.isNotEmpty ? riskValues.length : 1;
    final healthScore = (lowCount / totalCount * 100).round();
    
    // Generate recommendations and insights
    final recommendations = _generateRecommendations(risks);
    final insights = _generateInsights(outputs, risks);
    
    return HealthAssessmentResult(
      // Original scan results
      heartRate: scanResults['heartRate'] ?? 0,
      heartRateVariability: scanResults['heartRateVariability'] ?? 0,
      respiratoryRate: scanResults['respiratoryRate'] ?? 0,
      oxygenSaturation: toInt(scanResults['oxygenSaturation']) ?? toInt(outputs['int_raw_oxygen']) ?? 98,
      systolicBP: scanResults['systolicBP'] ?? 0,
      diastolicBP: scanResults['diastolicBP'] ?? 0,
      stressLevel: _normalizeStressLevel(scanResults['stressLevel']),
      
      // Lambda-enhanced metrics (with type conversion)
      healthScore: healthScore,
      heartAge: toInt(outputs['yr_raw_age']) != null ? toInt(outputs['yr_raw_age'])! + 5 : null,
      biologicalAge: toInt(outputs['yr_raw_age']),
      arterialStiffness: toDouble(outputs['cms_adj_bapwv']),
      bmi: toDouble(outputs['kgsm_raw_bmi']),
      
      // Cholesterol panel (with type conversion)
      totalCholesterol: toDouble(outputs['mmoll_raw_corrTotalCholesterolMean']),
      ldlCholesterol: toDouble(outputs['mmoll_raw_corrLdlMean']),
      hdlCholesterol: toDouble(outputs['mmoll_raw_corrHdlcMean']),
      triglycerides: toDouble(outputs['mmoll_raw_corrTriglyceridesMean']),
      
      // Fitness metrics (with type conversion)
      fitnessScore: toDouble(outputs['num_raw_fitnessAvg']),
      vo2Max: toDouble(outputs['num_raw_fitnessAvg']),
      cvdRisk10Year: toDouble(outputs['num_raw_tenYrCvd']),
      framinghamScore: toInt(outputs['int_raw_framinghamScore']),
      
      // Risk assessments
      cardiovascularRisk: risks['risk_adj_tenYrCvd'] ?? 'low',
      diabetesRisk: risks['risk_adj_metSComp'] ?? 'low',
      metabolicRisk: risks['risk_adj_metSComp'] ?? 'low',
      cholesterolRisk: risks['risk_adj_totalCholesterol'] ?? 'low',

      // Full risk breakdown forwarded to the results screen.
      riskBreakdown: {
        for (final e in risks.entries)
          if (e.key.toString().startsWith('risk_adj_') && e.value != null)
            e.key.toString(): e.value.toString(),
      },
      
      // Insights
      recommendations: recommendations,
      insights: insights,
      
      // Metadata
      lambdaSuccess: true,
      timestamp: DateTime.now(),
    );
  }
  
  /// Generate recommendations based on risk assessment
  static List<String> _generateRecommendations(Map<String, dynamic> risks) {
    final recommendations = <String>[];
    
    if (risks['risk_adj_activityLevel'] == 'high') {
      recommendations.add('Increase physical activity to at least 150 minutes of moderate exercise per week');
    }
    if (risks['risk_adj_restingHeartRate'] == 'high') {
      recommendations.add('Consider cardiovascular exercise to improve resting heart rate');
    }
    if (risks['risk_adj_bapwv'] == 'high') {
      recommendations.add('Focus on cardiovascular health to improve arterial stiffness');
    }
    if (risks['risk_adj_metSComp'] == 'high') {
      recommendations.add('Monitor metabolic health markers and consider dietary changes');
    }
    if (risks['risk_adj_bloodPressure'] == 'high') {
      recommendations.add('Monitor blood pressure regularly and reduce sodium intake');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('Maintain your current healthy lifestyle habits');
    }
    
    return recommendations;
  }
  
  /// Generate insights based on Lambda data
  static List<String> _generateInsights(
    Map<String, dynamic> outputs,
    Map<String, dynamic> risks,
  ) {
    final insights = <String>[];
    
    // BMI insight
    if (outputs['kgsm_raw_bmi'] != null) {
      final bmi = outputs['kgsm_raw_bmi'];
      if (bmi < 18.5) {
        insights.add('Your BMI indicates you are underweight');
      } else if (bmi < 25) {
        insights.add('Your BMI is in the healthy range');
      } else if (bmi < 30) {
        insights.add('Your BMI indicates you are overweight');
      } else {
        insights.add('Your BMI indicates obesity');
      }
    }
    
    // Risk summary
    final highRisks = risks.entries
        .where((e) => e.value == 'high')
        .map((e) => e.key.replaceAll('risk_adj_', '').replaceAll('_', ' '))
        .toList();
    
    if (highRisks.isEmpty) {
      insights.add('All health risk indicators are within acceptable ranges');
    } else {
      insights.add('${highRisks.length} health indicator(s) require attention: ${highRisks.join(', ')}');
    }
    
    // Fitness insight
    if (outputs['num_raw_fitnessAvg'] != null) {
      final fitness = outputs['num_raw_fitnessAvg'];
      if (fitness >= 35) {
        insights.add('Your cardiovascular fitness level is good');
      } else if (fitness >= 30) {
        insights.add('Your cardiovascular fitness level is average');
      } else {
        insights.add('Consider improving your cardiovascular fitness');
      }
    }
    
    return insights;
  }
}

/// Health assessment result model
class HealthAssessmentResult {
  // Basic vital signs
  final int heartRate;
  final int heartRateVariability;
  final int respiratoryRate;
  final int oxygenSaturation;
  final int systolicBP;
  final int diastolicBP;
  final String stressLevel;
  
  // Lambda-enhanced metrics
  final int? healthScore;
  final int? heartAge;
  final int? biologicalAge;
  final double? arterialStiffness;
  final double? bmi;
  
  // Cholesterol panel
  final double? totalCholesterol;
  final double? ldlCholesterol;
  final double? hdlCholesterol;
  final double? triglycerides;
  
  // Fitness metrics
  final double? fitnessScore;
  final double? vo2Max;
  final double? cvdRisk10Year;
  final int? framinghamScore;
  
  // Risk assessments
  final String? cardiovascularRisk;
  final String? diabetesRisk;
  final String? metabolicRisk;
  final String? cholesterolRisk;

  /// Full lambda risk breakdown: every `risk_adj_*` key → "low"/"medium"/"high".
  /// Empty when the lambda call wasn't made (fromScanOnly fallback).
  final Map<String, String> riskBreakdown;
  
  // Insights
  final List<String> recommendations;
  final List<String> insights;
  
  // Metadata
  final bool lambdaSuccess;
  final DateTime timestamp;
  final String? lambdaError;
  
  HealthAssessmentResult({
    required this.heartRate,
    required this.heartRateVariability,
    required this.respiratoryRate,
    required this.oxygenSaturation,
    required this.systolicBP,
    required this.diastolicBP,
    required this.stressLevel,
    this.healthScore,
    this.heartAge,
    this.biologicalAge,
    this.arterialStiffness,
    this.bmi,
    this.totalCholesterol,
    this.ldlCholesterol,
    this.hdlCholesterol,
    this.triglycerides,
    this.fitnessScore,
    this.vo2Max,
    this.cvdRisk10Year,
    this.framinghamScore,
    this.cardiovascularRisk,
    this.diabetesRisk,
    this.metabolicRisk,
    this.cholesterolRisk,
    this.riskBreakdown = const {},
    required this.recommendations,
    required this.insights,
    required this.lambdaSuccess,
    required this.timestamp,
    this.lambdaError,
  });
  
  /// Create result from scan data only (when Lambda fails)
  factory HealthAssessmentResult.fromScanOnly(Map<String, dynamic> scanResults) {
    return HealthAssessmentResult(
      heartRate: scanResults['heartRate'] ?? 0,
      heartRateVariability: scanResults['heartRateVariability'] ?? 0,
      respiratoryRate: scanResults['respiratoryRate'] ?? 0,
      oxygenSaturation: scanResults['oxygenSaturation'] ?? 0,
      systolicBP: scanResults['systolicBP'] ?? 0,
      diastolicBP: scanResults['diastolicBP'] ?? 0,
      stressLevel: LambdaService._normalizeStressLevel(scanResults['stressLevel']),
      recommendations: ['Complete health assessment unavailable. Basic vital signs shown.'],
      insights: ['Advanced health metrics require successful Lambda connection.'],
      lambdaSuccess: false,
      timestamp: DateTime.now(),
      lambdaError: 'Lambda service unavailable',
    );
  }
  
  Map<String, dynamic> toJson() => {
    'heartRate': heartRate,
    'heartRateVariability': heartRateVariability,
    'respiratoryRate': respiratoryRate,
    'oxygenSaturation': oxygenSaturation,
    'systolicBP': systolicBP,
    'diastolicBP': diastolicBP,
    'stressLevel': stressLevel,
    'healthScore': healthScore,
    'heartAge': heartAge,
    'biologicalAge': biologicalAge,
    'arterialStiffness': arterialStiffness,
    'bmi': bmi,
    'totalCholesterol': totalCholesterol,
    'ldlCholesterol': ldlCholesterol,
    'hdlCholesterol': hdlCholesterol,
    'triglycerides': triglycerides,
    'fitnessScore': fitnessScore,
    'vo2Max': vo2Max,
    'cvdRisk10Year': cvdRisk10Year,
    'framinghamScore': framinghamScore,
    'cardiovascularRisk': cardiovascularRisk,
    'diabetesRisk': diabetesRisk,
    'metabolicRisk': metabolicRisk,
    'cholesterolRisk': cholesterolRisk,
    'recommendations': recommendations,
    'insights': insights,
    'lambdaSuccess': lambdaSuccess,
    'timestamp': timestamp.toIso8601String(),
    'lambdaError': lambdaError,
  };
}