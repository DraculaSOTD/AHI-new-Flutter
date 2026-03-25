import 'package:equatable/equatable.dart';
import 'scan_enums.dart';
import 'scan_inputs.dart';
import 'dart:convert';

/// Base class for scan results
abstract class ScanResult extends Equatable {
  final DateTime scanDate;
  final Map<String, dynamic> rawJson;
  final String? dbKey;

  const ScanResult({
    required this.scanDate,
    required this.rawJson,
    this.dbKey,
  });

  /// Convert to object for storage
  Map<String, dynamic> toObject();

  /// Get scan type
  ScanResultType get scanType;
}

/// Body scan result with measurements and 3D mesh
class BodyScanResult extends ScanResult {
  final BodyScanInputs inputs;
  String? meshPath;

  BodyScanResult({
    required super.scanDate,
    required super.rawJson,
    required this.inputs,
    super.dbKey,
    this.meshPath,
  });

  @override
  ScanResultType get scanType => ScanResultType.bodyStandalone;

  // Input validation echoes
  String get biologicalSex => rawJson['enum_ent_sex'] as String? ?? inputs.sex.toLabel();
  double get weightInKg => (rawJson['kg_ent_weight'] as num?)?.toDouble() ?? inputs.weightInKg;
  double get heightInCm => (rawJson['cm_ent_height'] as num?)?.toDouble() ?? inputs.heightInCm;
  int get ageInYears => rawJson['miscData']?['yr_ent_age'] as int? ?? inputs.ageInYears;

  // Raw ML model outputs
  double? get rawWeightPredictInKg => (rawJson['kg_raw_weightPredict'] as num?)?.toDouble();
  double? get rawWaistInCm => (rawJson['cm_raw_waist'] as num?)?.toDouble();
  double? get rawInseamInCm => (rawJson['cm_raw_inseam'] as num?)?.toDouble();
  double? get rawThighInCm => (rawJson['cm_raw_thigh'] as num?)?.toDouble();
  double? get rawHipsInCm => (rawJson['cm_raw_hips'] as num?)?.toDouble();
  double? get rawChestInCm => (rawJson['cm_raw_chest'] as num?)?.toDouble();
  double? get rawBodyfatPercent => (rawJson['percent_raw_bodyFat'] as num?)?.toDouble();

  // Adjusted/calibrated measurements (preferred)
  double? get adjWeightPredictInKg => (rawJson['kg_adj_weightPredict'] as num?)?.toDouble();
  double? get adjWaistInCm => (rawJson['cm_adj_waist'] as num?)?.toDouble();
  double? get adjThighInCm => (rawJson['cm_adj_thigh'] as num?)?.toDouble();
  double? get adjHipsInCm => (rawJson['cm_adj_hips'] as num?)?.toDouble();
  double? get adjChestInCm => (rawJson['cm_adj_chest'] as num?)?.toDouble();
  double? get adjBodyfatPercent => (rawJson['percent_adj_bodyFat'] as num?)?.toDouble();
  double? get adjInseamInCm => (rawJson['cm_adj_inseam'] as num?)?.toDouble();

  // Best available measurements (adjusted preferred, fallback to raw)
  double? get weightPredictInKg => adjWeightPredictInKg ?? rawWeightPredictInKg;
  double? get waistInCm => adjWaistInCm ?? rawWaistInCm;
  double? get inseamInCm => adjInseamInCm ?? rawInseamInCm;
  double? get thighInCm => adjThighInCm ?? rawThighInCm;
  double? get hipsInCm => adjHipsInCm ?? rawHipsInCm;
  double? get chestInCm => adjChestInCm ?? rawChestInCm;
  double? get bodyfatInPercent => adjBodyfatPercent ?? rawBodyfatPercent;

  // Calculated metrics
  double? get muscleMassInKg {
    if (bodyfatInPercent != null && weightInKg > 0) {
      return weightInKg * (1 - (bodyfatInPercent! / 100));
    }
    return null;
  }

  double? get fatMassInKg {
    if (bodyfatInPercent != null && weightInKg > 0) {
      return weightInKg * (bodyfatInPercent! / 100);
    }
    return null;
  }

  double? get waistToHeightRatio {
    if (waistInCm != null && heightInCm > 0) {
      return waistInCm! / heightInCm;
    }
    return null;
  }

  double? get waistToHipRatio {
    if (waistInCm != null && hipsInCm != null && hipsInCm! > 0) {
      return waistInCm! / hipsInCm!;
    }
    return null;
  }

  /// Get all measurements as a map
  Map<String, double?> get measurements => {
        'chest': chestInCm,
        'waist': waistInCm,
        'hips': hipsInCm,
        'thigh': thighInCm,
        'inseam': inseamInCm,
        'bodyFat': bodyfatInPercent,
        'weightPredict': weightPredictInKg,
        'muscleMass': muscleMassInKg,
        'fatMass': fatMassInKg,
        'waistToHeight': waistToHeightRatio,
        'waistToHip': waistToHipRatio,
      };

  @override
  Map<String, dynamic> toObject() {
    return {
      'scanDate': scanDate.toIso8601String(),
      'rawJson': rawJson,
      'inputs': inputs.toObject(),
      'meshPath': meshPath,
      'dbKey': dbKey,
    };
  }

  /// Convert to JSON for serialization (alias for toObject for consistency)
  Map<String, dynamic> toJson() => toObject();

  /// Create from JSON response and inputs
  factory BodyScanResult.fromJson(Map<String, dynamic> json, BodyScanInputs inputs) {
    return BodyScanResult(
      scanDate: DateTime.now(),
      rawJson: json,
      inputs: inputs,
    );
  }

  /// Create from stored object
  factory BodyScanResult.fromObject(Map<String, dynamic> obj) {
    return BodyScanResult(
      scanDate: DateTime.parse(obj['scanDate'] as String),
      rawJson: obj['rawJson'] as Map<String, dynamic>,
      inputs: BodyScanInputs.fromObject(obj['inputs'] as Map<String, dynamic>),
      meshPath: obj['meshPath'] as String?,
      dbKey: obj['dbKey'] as String?,
    );
  }

  /// Create from production WebSocket data
  factory BodyScanResult.fromProductionData(Map<String, dynamic> data, BodyScanInputs inputs) {
    // Transform VastMindz WebSocket data to expected format
    final transformedData = {
      'enum_ent_sex': inputs.sex.toLabel(),
      'kg_ent_weight': inputs.weightInKg,
      'cm_ent_height': inputs.heightInCm,
      'miscData': {'yr_ent_age': inputs.ageInYears},
      
      // Map production data to expected fields
      'cm_adj_waist': data['waist_cm'],
      'cm_adj_chest': data['chest_cm'],
      'cm_adj_hips': data['hips_cm'],
      'cm_adj_thigh': data['thigh_cm'],
      'cm_adj_inseam': data['inseam_cm'],
      'percent_adj_bodyFat': data['body_fat_percent'],
      'kg_adj_weightPredict': data['weight_predict_kg'],
    };
    
    return BodyScanResult(
      scanDate: DateTime.now(),
      rawJson: transformedData,
      inputs: inputs,
    );
  }

  BodyScanResult copyWith({
    DateTime? scanDate,
    Map<String, dynamic>? rawJson,
    BodyScanInputs? inputs,
    String? meshPath,
    String? dbKey,
  }) {
    return BodyScanResult(
      scanDate: scanDate ?? this.scanDate,
      rawJson: rawJson ?? this.rawJson,
      inputs: inputs ?? this.inputs,
      meshPath: meshPath ?? this.meshPath,
      dbKey: dbKey ?? this.dbKey,
    );
  }

  @override
  List<Object?> get props => [scanDate, rawJson, inputs, meshPath];
}

/// Face scan result with health biomarkers
class FaceScanResult extends ScanResult {
  final FaceScanInputs inputs;
  final ScanResultType type;

  const FaceScanResult({
    required super.scanDate,
    required super.rawJson,
    required this.inputs,
    required this.type,
    super.dbKey,
  });

  @override
  ScanResultType get scanType => type;

  // Input validation echoes
  String get biologicalSex => rawJson['enum_ent_sex'] as String? ?? inputs.sex.toLabel();
  double get weightInKg => (rawJson['kg_ent_weight'] as num?)?.toDouble() ?? inputs.weightInKg;
  double get heightInCm => (rawJson['cm_ent_height'] as num?)?.toDouble() ?? inputs.heightInCm;
  int get ageInYears => rawJson['yr_ent_age'] as int? ?? inputs.ageInYears;

  // Cardiac metrics
  double? get heartRatePerMin => (rawJson['bpm_raw_heartRateBPM'] as num?)?.toDouble() ?? 
      ((rawJson['hz_raw_heartRate'] as num?)?.toDouble() != null 
          ? (rawJson['hz_raw_heartRate'] as num).toDouble() * 60.0 
          : null);
  double? get heartRateHz => (rawJson['hz_raw_heartRate'] as num?)?.toDouble();
  double? get heartRateVariability => (rawJson['sdnn_raw_heartRateVariability'] as num?)?.toDouble();
  double? get heartRateIrregularPerMin => (rawJson['bpm_raw_heartRateIrregular'] as num?)?.toDouble();
  double? get cardiacWorkload => (rawJson['db_raw_cardiacWorkload'] as num?)?.toDouble();

  // Blood pressure analysis
  double? get bloodPressureSystolic => (rawJson['mmHg_raw_bloodPressureSystolic'] as num?)?.toDouble();
  double? get bloodPressureDiastolic => (rawJson['mmHg_raw_bloodPressureDiastolic'] as num?)?.toDouble();
  double? get meanCorrectedSystolic => (rawJson['mean_corrected_sbp'] as num?)?.toDouble();
  double? get meanCorrectedDiastolic => (rawJson['mean_corrected_dbp'] as num?)?.toDouble();

  // Respiratory metrics
  double? get breathingRatePerMin => (rawJson['bpm_raw_breathingRate'] as num?)?.toDouble();
  double? get breathingRateHz => (rawJson['hz_raw_breathingRate'] as num?)?.toDouble();

  // Risk assessment
  double? get cardiovascularDiseaseRiskAsPercent => (rawJson['percent_raw_cardiovascularDiseaseRisk'] as num?)?.toDouble();
  double? get strokeRiskAsPercent => (rawJson['percent_raw_strokeRisk'] as num?)?.toDouble();
  double? get heartAttackRiskAsPercent => (rawJson['percent_raw_heartAttackRisk'] as num?)?.toDouble();
  double? get vascularCapacity => (rawJson['secs_raw_vascularCapacity'] as num?)?.toDouble();

  // Mental health indicators
  double? get mentalStressIndex => (rawJson['index_raw_mentalStressIndex'] as num?)?.toDouble();

  // Blood pressure distribution (6 categories: hypotension, normal, elevated, stage1, stage2, crisis)
  List<double>? get bloodPressureDistribution {
    final list = rawJson['probability_density_distribution'] as List?;
    return list?.cast<num>().map((num e) => e.toDouble()).toList();
  }

  /// Get all health metrics as a map
  Map<String, double?> get healthMetrics => {
        'heartRate': heartRatePerMin,
        'heartRateVariability': heartRateVariability,
        'systolicBP': bloodPressureSystolic,
        'diastolicBP': bloodPressureDiastolic,
        'breathingRate': breathingRatePerMin,
        'cardiacWorkload': cardiacWorkload,
        'cvdRisk': cardiovascularDiseaseRiskAsPercent,
        'strokeRisk': strokeRiskAsPercent,
        'heartAttackRisk': heartAttackRiskAsPercent,
        'stressIndex': mentalStressIndex,
        'vascularCapacity': vascularCapacity,
      };

  @override
  Map<String, dynamic> toObject() {
    return {
      'scanDate': scanDate.toIso8601String(),
      'rawJson': rawJson,
      'inputs': inputs.toObject(),
      'type': type.toLabel(),
      'dbKey': dbKey,
    };
  }

  /// Create from JSON response and inputs
  factory FaceScanResult.fromJson(Map<String, dynamic> json, FaceScanInputs inputs) {
    return FaceScanResult(
      scanDate: DateTime.now(),
      rawJson: json,
      inputs: inputs,
      type: ScanResultType.faceStandalone,
    );
  }

  /// Create from stored object
  factory FaceScanResult.fromObject(Map<String, dynamic> obj) {
    return FaceScanResult(
      scanDate: DateTime.parse(obj['scanDate'] as String),
      rawJson: obj['rawJson'] as Map<String, dynamic>,
      inputs: FaceScanInputs.fromObject(obj['inputs'] as Map<String, dynamic>),
      type: ScanResultType.fromString(obj['type'] as String),
      dbKey: obj['dbKey'] as String?,
    );
  }

  /// Create from production WebSocket data
  factory FaceScanResult.fromProductionData(Map<String, dynamic> data, FaceScanInputs inputs) {
    // Transform VastMindz WebSocket data to expected format
    final transformedData = {
      'enum_ent_sex': inputs.sex.toLabel(),
      'kg_ent_weight': inputs.weightInKg,
      'cm_ent_height': inputs.heightInCm,
      'yr_ent_age': inputs.ageInYears,
      
      // Map production data to expected fields
      'bpm_raw_heartRateBPM': data['heart_rate_bpm'],
      'hz_raw_heartRate': data['heart_rate_hz'],
      'sdnn_raw_heartRateVariability': data['hrv_sdnn'],
      'mmHg_raw_bloodPressureSystolic': data['systolic_bp'],
      'mmHg_raw_bloodPressureDiastolic': data['diastolic_bp'],
      'bpm_raw_breathingRate': data['breathing_rate_bpm'],
      'db_raw_cardiacWorkload': data['cardiac_workload'],
      'percent_raw_cardiovascularDiseaseRisk': data['cvd_risk_percent'],
      'percent_raw_strokeRisk': data['stroke_risk_percent'],
      'percent_raw_heartAttackRisk': data['heart_attack_risk_percent'],
      'index_raw_mentalStressIndex': data['stress_index'],
      'secs_raw_vascularCapacity': data['vascular_capacity'],
    };
    
    return FaceScanResult(
      scanDate: DateTime.now(),
      rawJson: transformedData,
      inputs: inputs,
      type: ScanResultType.faceStandalone,
    );
  }

  @override
  List<Object?> get props => [scanDate, rawJson, inputs, type];
}

/// Finger scan result with HRV analysis
class FingerScanResult extends ScanResult {
  final FingerScanInputs inputs;

  const FingerScanResult({
    required super.scanDate,
    required super.rawJson,
    required this.inputs,
    super.dbKey,
  });

  @override
  ScanResultType get scanType => ScanResultType.fingerStandalone;

  // Input validation echoes
  String get biologicalSex => rawJson['enum_ent_sex'] as String? ?? inputs.sex.toLabel();
  int get ageInYears => rawJson['yr_ent_age'] as int? ?? inputs.ageInYears;
  String get scanTypeLabel => inputs.scanType.toLabel();

  // Primary heart rate metrics
  double? get bpmHeartRate => (rawJson['bpm_adj_heartRate'] as num?)?.toDouble() ?? 
      (rawJson['bpm_raw_heartRate'] as num?)?.toDouble();
  
  List<double>? get listHeartRate {
    final hr = rawJson['list_raw_heartRate'];
    if (hr is List) {
      return hr.cast<num>().map((num e) => e.toDouble()).toList();
    } else if (hr is String) {
      try {
        final decoded = jsonDecode(hr) as List;
        return decoded.cast<num>().map((num e) => e.toDouble()).toList();
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Heart Rate Variability (HRV) metrics
  double? get hrvAVNN => (rawJson['hrv_raw_AVNN'] as num?)?.toDouble();
  double? get hrvHF => (rawJson['hrv_raw_HF'] as num?)?.toDouble();
  double? get hrvLF => (rawJson['hrv_raw_LF'] as num?)?.toDouble();
  double? get hrvLFHF => (rawJson['hrv_raw_lfhf'] as num?)?.toDouble();
  double? get hrvPNN20 => (rawJson['hrv_raw_pNN20'] as num?)?.toDouble();
  double? get hrvPNN50 => (rawJson['hrv_raw_pNN50'] as num?)?.toDouble();
  double? get hrvRMSSD => (rawJson['hrv_raw_rmssd'] as num?)?.toDouble();
  double? get hrvSDNN => (rawJson['hrv_raw_SDNN'] as num?)?.toDouble();

  // Signal quality metrics
  double? get indexBadSamples => (rawJson['index_raw_badSamples'] as num?)?.toDouble();
  double? get indexErrors => (rawJson['index_raw_errors'] as num?)?.toDouble();
  double? get indexQuality => (rawJson['index_raw_quality'] as num?)?.toDouble();

  // Raw signal data
  String? get listRRIntervals => rawJson['list_raw_rrIntervals']?.toString();
  String? get listPPGData => rawJson['listPPGData']?.toString();

  // Success indicator (1 if successful scan with >5 heartbeats)
  int get successIndicator => (listHeartRate?.length ?? 0) > 5 ? 1 : 0;
  bool get isValidScan => successIndicator == 1;

  /// Get all HRV metrics as a map
  Map<String, double?> get hrvMetrics => {
        'heartRate': bpmHeartRate,
        'AVNN': hrvAVNN,
        'HF': hrvHF,
        'LF': hrvLF,
        'LFHF': hrvLFHF,
        'pNN20': hrvPNN20,
        'pNN50': hrvPNN50,
        'RMSSD': hrvRMSSD,
        'SDNN': hrvSDNN,
      };

  /// Get signal quality metrics as a map
  Map<String, double?> get qualityMetrics => {
        'badSamples': indexBadSamples,
        'errors': indexErrors,
        'quality': indexQuality,
      };

  @override
  Map<String, dynamic> toObject() {
    return {
      'scanDate': scanDate.toIso8601String(),
      'rawJson': rawJson,
      'inputs': inputs.toObject(),
      'dbKey': dbKey,
    };
  }

  /// Create from JSON response and inputs
  factory FingerScanResult.fromJson(Map<String, dynamic> json, FingerScanInputs inputs) {
    return FingerScanResult(
      scanDate: DateTime.now(),
      rawJson: json,
      inputs: inputs,
    );
  }

  /// Create from stored object
  factory FingerScanResult.fromObject(Map<String, dynamic> obj) {
    return FingerScanResult(
      scanDate: DateTime.parse(obj['scanDate'] as String),
      rawJson: obj['rawJson'] as Map<String, dynamic>,
      inputs: FingerScanInputs.fromObject(obj['inputs'] as Map<String, dynamic>),
      dbKey: obj['dbKey'] as String?,
    );
  }

  /// Create from production WebSocket data
  factory FingerScanResult.fromProductionData(Map<String, dynamic> data, FingerScanInputs inputs) {
    // Transform VastMindz WebSocket data to expected format
    final transformedData = {
      'enum_ent_sex': inputs.sex.toLabel(),
      'yr_ent_age': inputs.ageInYears,
      
      // Map production data to expected fields
      'bpm_adj_heartRate': data['heart_rate_bpm'],
      'list_raw_heartRate': data['heart_rate_list'],
      'hrv_raw_AVNN': data['hrv_avnn'],
      'hrv_raw_HF': data['hrv_hf'],
      'hrv_raw_LF': data['hrv_lf'],
      'hrv_raw_lfhf': data['hrv_lf_hf_ratio'],
      'hrv_raw_pNN20': data['hrv_pnn20'],
      'hrv_raw_pNN50': data['hrv_pnn50'],
      'hrv_raw_rmssd': data['hrv_rmssd'],
      'hrv_raw_SDNN': data['hrv_sdnn'],
      'index_raw_badSamples': data['bad_samples_index'],
      'index_raw_errors': data['errors_index'],
      'index_raw_quality': data['quality_index'],
      'list_raw_rrIntervals': data['rr_intervals'],
      'listPPGData': data['ppg_data'],
    };
    
    return FingerScanResult(
      scanDate: DateTime.now(),
      rawJson: transformedData,
      inputs: inputs,
    );
  }

  @override
  List<Object?> get props => [scanDate, rawJson, inputs];
}