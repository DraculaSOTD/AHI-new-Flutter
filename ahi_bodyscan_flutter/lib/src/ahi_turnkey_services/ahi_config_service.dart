//
//  AHI Config Service - Manages configuration data from JSON assets
//
//  Copyright (c) AHI. All rights reserved.
//

import 'dart:convert';
import 'package:flutter/services.dart';
import '../ahi_turnkey_assets/ahi_assets.dart';

class AHIConfigService {
  static final AHIConfigService _instance = AHIConfigService._internal();
  factory AHIConfigService() => _instance;
  AHIConfigService._internal();

  // Cache for loaded configurations
  final Map<String, dynamic> _configCache = {};

  /// Load JSON configuration from assets
  Future<Map<String, dynamic>> loadConfig(String assetPath) async {
    if (_configCache.containsKey(assetPath)) {
      return _configCache[assetPath];
    }

    try {
      final String jsonString = await rootBundle.loadString(assetPath);
      final Map<String, dynamic> config = json.decode(jsonString);
      _configCache[assetPath] = config;
      return config;
    } catch (e) {
      throw Exception('Failed to load config from $assetPath: $e');
    }
  }

  /// Load body fat percentage classifications
  Future<Map<String, dynamic>> loadBodyFatClassifications() async {
    return loadConfig(AHIAssets.bodyFatPercentage);
  }

  /// Load blood pressure classifications
  Future<Map<String, dynamic>> loadBloodPressureClassifications() async {
    return loadConfig(AHIAssets.bloodPressure);
  }

  /// Load BMI classifications
  Future<Map<String, dynamic>> loadBMIClassifications() async {
    return loadConfig(AHIAssets.bodyMassIndex);
  }

  /// Load cardiovascular disease risk classifications
  Future<Map<String, dynamic>> loadCVDRiskClassifications() async {
    return loadConfig(AHIAssets.cardiovascularDisease);
  }

  /// Load anxiety survey configuration
  Future<Map<String, dynamic>> loadAnxietySurvey() async {
    return loadConfig(AHIAssets.surveyAnxiety);
  }

  /// Load depression survey configuration
  Future<Map<String, dynamic>> loadDepressionSurvey() async {
    return loadConfig(AHIAssets.surveyDepression);
  }

  /// Load profile survey configuration
  Future<Map<String, dynamic>> loadProfileSurvey() async {
    return loadConfig(AHIAssets.surveyProfile);
  }

  /// Load survey schema
  Future<Map<String, dynamic>> loadSurveySchema() async {
    return loadConfig(AHIAssets.surveySchema);
  }

  /// Load lipid lookup data
  Future<Map<String, dynamic>> loadLipidLookup(String lipidType) async {
    switch (lipidType.toLowerCase()) {
      case 'cholesterol':
        return loadConfig(AHIAssets.cholesterol);
      case 'hdl':
      case 'hdlc':
        return loadConfig(AHIAssets.hdlc);
      case 'ldl':
      case 'ldlc':
        return loadConfig(AHIAssets.ldlc);
      case 'triglycerides':
        return loadConfig(AHIAssets.triglycerides);
      default:
        throw Exception('Unknown lipid type: $lipidType');
    }
  }

  /// Get risk classification for a specific metric
  Future<String> classifyRisk(String metricType, double value, 
      {String? gender, int? age}) async {
    
    final config = await loadConfig('${'assets/ahi_turnkey/json/classifications'}/$metricType.json');
    
    // This is a simplified classification logic
    // In a real implementation, you would parse the complex JSON rules
    if (config.containsKey('classifications')) {
      final classifications = config['classifications'] as List;
      
      for (final classification in classifications) {
        final range = classification['range'];
        if (range != null && 
            value >= (range['min'] ?? double.negativeInfinity) &&
            value <= (range['max'] ?? double.infinity)) {
          return classification['level'] ?? 'normal';
        }
      }
    }
    
    return 'normal';
  }

  /// Clear configuration cache
  void clearCache() {
    _configCache.clear();
  }

  /// Preload essential configurations
  Future<void> preloadEssentialConfigs() async {
    try {
      await Future.wait([
        loadBodyFatClassifications(),
        loadBloodPressureClassifications(),
        loadBMIClassifications(),
        loadSurveySchema(),
      ]);
    } catch (e) {
      // Log error but don't throw to avoid blocking app startup
      print('Warning: Failed to preload some configurations: $e');
    }
  }
}