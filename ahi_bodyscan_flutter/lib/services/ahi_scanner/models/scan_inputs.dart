import 'package:equatable/equatable.dart';
import 'scan_enums.dart';

/// Base class for scan inputs
abstract class ScanInputs extends Equatable {
  const ScanInputs();
  
  /// Convert to options map for native SDK
  Map<String, dynamic> toOptionsMap();
  
  /// Convert to object for storage
  Map<String, dynamic> toObject();
  
  /// Validate input data
  bool isValid();
  
  /// Get validation errors
  List<String> getValidationErrors();
}

/// Body scan input parameters
class BodyScanInputs extends ScanInputs {
  final BiologicalSex sex;
  final double heightInCm;
  final double weightInKg;
  final int ageInYears;
  final EthnicityType ethnicity;

  const BodyScanInputs({
    required this.sex,
    required this.heightInCm,
    required this.weightInKg,
    required this.ageInYears,
    required this.ethnicity,
  });

  @override
  Map<String, dynamic> toOptionsMap() {
    return {
      'enum_ent_sex': sex.toLabel(),
      'cm_ent_height': heightInCm,
      'kg_ent_weight': weightInKg,
      'debug_isDebug': false,
    };
  }

  @override
  Map<String, dynamic> toObject() {
    return {
      'sex': sex.index,
      'heightInCm': heightInCm,
      'weightInKg': weightInKg,
      'ageInYears': ageInYears,
      'ethnicity': ethnicity.index,
    };
  }

  @override
  bool isValid() {
    return getValidationErrors().isEmpty;
  }

  @override
  List<String> getValidationErrors() {
    final errors = <String>[];
    
    if (heightInCm < 50 || heightInCm > 255) {
      errors.add('Height must be between 50 and 255 cm');
    }
    
    if (weightInKg < 16 || weightInKg > 300) {
      errors.add('Weight must be between 16 and 300 kg');
    }
    
    if (ageInYears < 1 || ageInYears > 120) {
      errors.add('Age must be between 1 and 120 years');
    }
    
    return errors;
  }

  /// Create from user data with validation
  factory BodyScanInputs.fromUserData({
    required BiologicalSex sex,
    required double heightInCm,
    required double weightInKg,
    required int ageInYears,
    EthnicityType? ethnicity,
  }) {
    return BodyScanInputs(
      sex: sex,
      heightInCm: heightInCm.clamp(50, 255),
      weightInKg: weightInKg.clamp(16, 300),
      ageInYears: ageInYears.clamp(1, 120),
      ethnicity: ethnicity ?? EthnicityType.other,
    );
  }

  /// Create from stored object
  factory BodyScanInputs.fromObject(Map<String, dynamic> obj) {
    return BodyScanInputs(
      sex: BiologicalSex.values[obj['sex'] as int],
      heightInCm: (obj['heightInCm'] as num).toDouble(),
      weightInKg: (obj['weightInKg'] as num).toDouble(),
      ageInYears: obj['ageInYears'] as int,
      ethnicity: EthnicityType.values[obj['ethnicity'] as int],
    );
  }

  BodyScanInputs copyWith({
    BiologicalSex? sex,
    double? heightInCm,
    double? weightInKg,
    int? ageInYears,
    EthnicityType? ethnicity,
  }) {
    return BodyScanInputs(
      sex: sex ?? this.sex,
      heightInCm: heightInCm ?? this.heightInCm,
      weightInKg: weightInKg ?? this.weightInKg,
      ageInYears: ageInYears ?? this.ageInYears,
      ethnicity: ethnicity ?? this.ethnicity,
    );
  }

  @override
  List<Object?> get props => [sex, heightInCm, weightInKg, ageInYears, ethnicity];
}

/// Face scan input parameters
class FaceScanInputs extends ScanInputs {
  final BiologicalSex sex;
  final double heightInCm;
  final double weightInKg;
  final int ageInYears;
  final bool isSmoker;
  final bool hasHypertension;
  final bool hasBloodPressureMedication;
  final DiabetesType diabetesType;

  const FaceScanInputs({
    required this.sex,
    required this.heightInCm,
    required this.weightInKg,
    required this.ageInYears,
    required this.isSmoker,
    required this.hasHypertension,
    required this.hasBloodPressureMedication,
    required this.diabetesType,
  });

  @override
  Map<String, dynamic> toOptionsMap() {
    return {
      'enum_ent_sex': sex.toLabel(),
      'cm_ent_height': heightInCm,
      'kg_ent_weight': weightInKg,
      'yr_ent_age': ageInYears,
      'bool_ent_smoker': isSmoker,
      'bool_ent_hypertension': hasHypertension,
      'bool_ent_bloodPressureMedication': hasBloodPressureMedication,
      'enum_ent_diabetic': diabetesType.toFacescanLabel(),
    };
  }

  @override
  Map<String, dynamic> toObject() {
    return {
      'sex': sex.index,
      'heightInCm': heightInCm,
      'weightInKg': weightInKg,
      'ageInYears': ageInYears,
      'isSmoker': isSmoker,
      'hasHypertension': hasHypertension,
      'hasBloodPressureMedication': hasBloodPressureMedication,
      'diabetesType': diabetesType.index,
    };
  }

  @override
  bool isValid() {
    return getValidationErrors().isEmpty;
  }

  @override
  List<String> getValidationErrors() {
    final errors = <String>[];
    
    if (heightInCm < 120 || heightInCm > 220) {
      errors.add('Height must be between 120 and 220 cm');
    }
    
    if (weightInKg < 25 || weightInKg > 300) {
      errors.add('Weight must be between 25 and 300 kg');
    }
    
    if (ageInYears < 18 || ageInYears > 100) {
      errors.add('Age must be between 18 and 100 years');
    }
    
    return errors;
  }

  /// Create from user data with validation
  factory FaceScanInputs.fromUserData({
    required BiologicalSex sex,
    required double heightInCm,
    required double weightInKg,
    required int ageInYears,
    SmokerStatus? smokerStatus,
    bool? hasHypertension,
    bool? hasBloodPressureMedication,
    DiabetesType? diabetesType,
  }) {
    return FaceScanInputs(
      sex: sex,
      heightInCm: heightInCm.clamp(120, 220),
      weightInKg: weightInKg.clamp(25, 300),
      ageInYears: ageInYears.clamp(18, 100),
      isSmoker: smokerStatus?.isSmoker ?? false,
      hasHypertension: hasHypertension ?? false,
      hasBloodPressureMedication: hasBloodPressureMedication ?? false,
      diabetesType: diabetesType ?? DiabetesType.none,
    );
  }

  /// Create from stored object
  factory FaceScanInputs.fromObject(Map<String, dynamic> obj) {
    return FaceScanInputs(
      sex: BiologicalSex.values[obj['sex'] as int],
      heightInCm: (obj['heightInCm'] as num).toDouble(),
      weightInKg: (obj['weightInKg'] as num).toDouble(),
      ageInYears: obj['ageInYears'] as int,
      isSmoker: obj['isSmoker'] as bool,
      hasHypertension: obj['hasHypertension'] as bool,
      hasBloodPressureMedication: obj['hasBloodPressureMedication'] as bool,
      diabetesType: DiabetesType.values[obj['diabetesType'] as int],
    );
  }

  FaceScanInputs copyWith({
    BiologicalSex? sex,
    double? heightInCm,
    double? weightInKg,
    int? ageInYears,
    bool? isSmoker,
    bool? hasHypertension,
    bool? hasBloodPressureMedication,
    DiabetesType? diabetesType,
  }) {
    return FaceScanInputs(
      sex: sex ?? this.sex,
      heightInCm: heightInCm ?? this.heightInCm,
      weightInKg: weightInKg ?? this.weightInKg,
      ageInYears: ageInYears ?? this.ageInYears,
      isSmoker: isSmoker ?? this.isSmoker,
      hasHypertension: hasHypertension ?? this.hasHypertension,
      hasBloodPressureMedication: hasBloodPressureMedication ?? this.hasBloodPressureMedication,
      diabetesType: diabetesType ?? this.diabetesType,
    );
  }

  @override
  List<Object?> get props => [
        sex,
        heightInCm,
        weightInKg,
        ageInYears,
        isSmoker,
        hasHypertension,
        hasBloodPressureMedication,
        diabetesType,
      ];
}

/// Finger scan input parameters
class FingerScanInputs extends ScanInputs {
  final BiologicalSex sex;
  final int ageInYears;
  final FingerScanType scanType;

  const FingerScanInputs({
    required this.sex,
    required this.ageInYears,
    this.scanType = FingerScanType.resting,
  });

  @override
  Map<String, dynamic> toOptionsMap() {
    return {
      'enum_ent_sex': sex.toLabel(),
      'yr_ent_age': ageInYears,
    };
  }

  @override
  Map<String, dynamic> toObject() {
    return {
      'sex': sex.index,
      'ageInYears': ageInYears,
      'scanType': scanType.index,
    };
  }

  @override
  bool isValid() {
    return getValidationErrors().isEmpty;
  }

  @override
  List<String> getValidationErrors() {
    final errors = <String>[];
    
    if (ageInYears < 18 || ageInYears > 100) {
      errors.add('Age must be between 18 and 100 years');
    }
    
    return errors;
  }

  /// Create from user data with validation
  factory FingerScanInputs.fromUserData({
    required BiologicalSex sex,
    required int ageInYears,
    FingerScanType? scanType,
  }) {
    return FingerScanInputs(
      sex: sex,
      ageInYears: ageInYears.clamp(18, 100),
      scanType: scanType ?? FingerScanType.resting,
    );
  }

  /// Create from stored object
  factory FingerScanInputs.fromObject(Map<String, dynamic> obj) {
    return FingerScanInputs(
      sex: BiologicalSex.values[obj['sex'] as int],
      ageInYears: obj['ageInYears'] as int,
      scanType: FingerScanType.values[obj['scanType'] as int? ?? 0],
    );
  }

  FingerScanInputs copyWith({
    BiologicalSex? sex,
    int? ageInYears,
    FingerScanType? scanType,
  }) {
    return FingerScanInputs(
      sex: sex ?? this.sex,
      ageInYears: ageInYears ?? this.ageInYears,
      scanType: scanType ?? this.scanType,
    );
  }

  @override
  List<Object?> get props => [sex, ageInYears, scanType];
}