/// Biological sex enumeration for gender-specific ML models
enum BiologicalSex {
  male,
  female;

  String toLabel() {
    switch (this) {
      case BiologicalSex.male:
        return 'male';
      case BiologicalSex.female:
        return 'female';
    }
  }

  static BiologicalSex fromString(String value) {
    switch (value.toLowerCase()) {
      case 'male':
        return BiologicalSex.male;
      case 'female':
        return BiologicalSex.female;
      default:
        throw ArgumentError('Invalid biological sex: $value');
    }
  }
}

/// Ethnicity types for model selection and risk calculations
enum EthnicityType {
  caucasian,
  african,
  asian,
  hispanic,
  middleEastern,
  pacific,
  other;

  String toLabel() {
    switch (this) {
      case EthnicityType.caucasian:
        return 'caucasian';
      case EthnicityType.african:
        return 'african';
      case EthnicityType.asian:
        return 'asian';
      case EthnicityType.hispanic:
        return 'hispanic';
      case EthnicityType.middleEastern:
        return 'middle_eastern';
      case EthnicityType.pacific:
        return 'pacific';
      case EthnicityType.other:
        return 'other';
    }
  }

  static EthnicityType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'caucasian':
        return EthnicityType.caucasian;
      case 'african':
        return EthnicityType.african;
      case 'asian':
        return EthnicityType.asian;
      case 'hispanic':
        return EthnicityType.hispanic;
      case 'middle_eastern':
        return EthnicityType.middleEastern;
      case 'pacific':
        return EthnicityType.pacific;
      case 'other':
        return EthnicityType.other;
      default:
        return EthnicityType.other;
    }
  }
}

/// Diabetes type classification
enum DiabetesType {
  none,
  type1,
  type2,
  prediabetes,
  gestational;

  String toLabel() {
    switch (this) {
      case DiabetesType.none:
        return 'none';
      case DiabetesType.type1:
        return 'type1';
      case DiabetesType.type2:
        return 'type2';
      case DiabetesType.prediabetes:
        return 'prediabetes';
      case DiabetesType.gestational:
        return 'gestational';
    }
  }

  String toFacescanLabel() {
    switch (this) {
      case DiabetesType.none:
        return 'none';
      case DiabetesType.type1:
      case DiabetesType.type2:
      case DiabetesType.gestational:
        return 'diabetes';
      case DiabetesType.prediabetes:
        return 'prediabetes';
    }
  }

  static DiabetesType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'none':
        return DiabetesType.none;
      case 'type1':
        return DiabetesType.type1;
      case 'type2':
        return DiabetesType.type2;
      case 'prediabetes':
        return DiabetesType.prediabetes;
      case 'gestational':
        return DiabetesType.gestational;
      case 'diabetes':
        return DiabetesType.type2; // Default to type 2
      default:
        return DiabetesType.none;
    }
  }
}

/// Finger scan type classification
enum FingerScanType {
  resting,
  fitness,
  standalone;

  String toLabel() {
    switch (this) {
      case FingerScanType.resting:
        return 'resting';
      case FingerScanType.fitness:
        return 'fitness';
      case FingerScanType.standalone:
        return 'standalone';
    }
  }

  static FingerScanType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'resting':
        return FingerScanType.resting;
      case 'fitness':
        return FingerScanType.fitness;
      case 'standalone':
        return FingerScanType.standalone;
      default:
        return FingerScanType.resting;
    }
  }
}

/// Scan result type classification
enum ScanResultType {
  bodyStandalone,
  faceStandalone,
  fingerStandalone,
  bhaLevel1,
  bhaLevel2,
  bhaLevel3,
  bhaLevel4;

  String toLabel() {
    switch (this) {
      case ScanResultType.bodyStandalone:
        return 'SRT_STA_BODY';
      case ScanResultType.faceStandalone:
        return 'SRT_STA_FACE';
      case ScanResultType.fingerStandalone:
        return 'SRT_STA_FINGER';
      case ScanResultType.bhaLevel1:
        return 'SRT_BHA_LEVEL1';
      case ScanResultType.bhaLevel2:
        return 'SRT_BHA_LEVEL2';
      case ScanResultType.bhaLevel3:
        return 'SRT_BHA_LEVEL3';
      case ScanResultType.bhaLevel4:
        return 'SRT_BHA_LEVEL4';
    }
  }

  static ScanResultType fromString(String value) {
    switch (value) {
      case 'SRT_STA_BODY':
        return ScanResultType.bodyStandalone;
      case 'SRT_STA_FACE':
        return ScanResultType.faceStandalone;
      case 'SRT_STA_FINGER':
        return ScanResultType.fingerStandalone;
      case 'SRT_BHA_LEVEL1':
        return ScanResultType.bhaLevel1;
      case 'SRT_BHA_LEVEL2':
        return ScanResultType.bhaLevel2;
      case 'SRT_BHA_LEVEL3':
        return ScanResultType.bhaLevel3;
      case 'SRT_BHA_LEVEL4':
        return ScanResultType.bhaLevel4;
      default:
        throw ArgumentError('Invalid scan result type: $value');
    }
  }
}

/// Smoker status classification
enum SmokerStatus {
  never,
  former,
  current;

  String toLabel() {
    switch (this) {
      case SmokerStatus.never:
        return 'Never';
      case SmokerStatus.former:
        return 'Former';
      case SmokerStatus.current:
        return 'Current';
    }
  }

  static SmokerStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'never':
        return SmokerStatus.never;
      case 'former':
        return SmokerStatus.former;
      case 'current':
        return SmokerStatus.current;
      default:
        return SmokerStatus.never;
    }
  }

  bool get isSmoker => this == SmokerStatus.current;
}