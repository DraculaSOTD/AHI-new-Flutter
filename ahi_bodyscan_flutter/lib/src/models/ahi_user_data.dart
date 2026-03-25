//
//  AHI User Data Model
//
//  Copyright (c) AHI. All rights reserved.
//

import 'package:equatable/equatable.dart';

enum TkBiologicalSex {
  BS_MALE,
  BS_FEMALE,
}

extension TkBiologicalSexExtension on TkBiologicalSex {
  String toLabel() {
    switch (this) {
      case TkBiologicalSex.BS_MALE:
        return 'male';
      case TkBiologicalSex.BS_FEMALE:
        return 'female';
    }
  }
}

enum TkEthnicityType {
  WHITE,
  BLACK_OR_AFRICAN_AMERICAN,
  AMERICAN_INDIAN_OR_ALASKA_NATIVE,
  ASIAN,
  NATIVE_HAWAIIAN_OR_OTHER_PACIFIC_ISLANDER,
  HISPANIC_OR_LATINO,
  OTHER,
}

class TkUserData extends Equatable {
  const TkUserData({
    this.key,
    this.email,
    this.biologicalSex,
    this.heightInCm = 170.0,
    this.weightInKg = 70.0,
    this.age,
    this.ethnicityType,
  });

  final String? key;
  final String? email;
  final TkBiologicalSex? biologicalSex;
  final double heightInCm;
  final double weightInKg;
  final int? age;
  final TkEthnicityType? ethnicityType;

  // Compatibility getter for age
  int? get ageInYears => age;

  bool isValidData() {
    return biologicalSex != null &&
           heightInCm > 0 &&
           weightInKg > 0 &&
           age != null &&
           age! > 0;
  }

  @override
  List<Object?> get props => [
        key,
        email,
        biologicalSex,
        heightInCm,
        weightInKg,
        age,
        ethnicityType,
      ];

  TkUserData copyWith({
    String? key,
    String? email,
    TkBiologicalSex? biologicalSex,
    double? heightInCm,
    double? weightInKg,
    int? age,
    TkEthnicityType? ethnicityType,
  }) {
    return TkUserData(
      key: key ?? this.key,
      email: email ?? this.email,
      biologicalSex: biologicalSex ?? this.biologicalSex,
      heightInCm: heightInCm ?? this.heightInCm,
      weightInKg: weightInKg ?? this.weightInKg,
      age: age ?? this.age,
      ethnicityType: ethnicityType ?? this.ethnicityType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'email': email,
      'biologicalSex': biologicalSex?.index,
      'heightInCm': heightInCm,
      'weightInKg': weightInKg,
      'age': age,
      'ethnicityType': ethnicityType?.index,
    };
  }

  factory TkUserData.fromJson(Map<String, dynamic> json) {
    return TkUserData(
      key: json['key'] as String?,
      email: json['email'] as String?,
      biologicalSex: json['biologicalSex'] != null
          ? TkBiologicalSex.values[json['biologicalSex'] as int]
          : null,
      heightInCm: (json['heightInCm'] as num?)?.toDouble() ?? 170.0,
      weightInKg: (json['weightInKg'] as num?)?.toDouble() ?? 70.0,
      age: json['age'] as int?,
      ethnicityType: json['ethnicityType'] != null
          ? TkEthnicityType.values[json['ethnicityType'] as int]
          : null,
    );
  }
}

class TkUserDataMutable {
  TkUserDataMutable({
    this.key,
    this.email,
    this.biologicalSex,
    this.heightInCm = 170.0,
    this.weightInKg = 70.0,
    this.age,
    this.ethnicityType,
  });

  String? key;
  String? email;
  TkBiologicalSex? biologicalSex;
  double? heightInCm;
  double? weightInKg;
  int? age;
  TkEthnicityType? ethnicityType;

  bool isValidData() {
    return biologicalSex != null && 
           heightInCm != null && heightInCm! > 0 && 
           weightInKg != null && weightInKg! > 0 && 
           age != null && age! > 0;
  }

  TkUserData toImmutable() {
    return TkUserData(
      key: key,
      email: email,
      biologicalSex: biologicalSex,
      heightInCm: heightInCm ?? 170.0,
      weightInKg: weightInKg ?? 70.0,
      age: age,
      ethnicityType: ethnicityType,
    );
  }

  factory TkUserDataMutable.fromImmutable(TkUserData userData) {
    return TkUserDataMutable(
      key: userData.key,
      email: userData.email,
      biologicalSex: userData.biologicalSex,
      heightInCm: userData.heightInCm,
      weightInKg: userData.weightInKg,
      age: userData.age,
      ethnicityType: userData.ethnicityType,
    );
  }
}

class TkBodyScanInputs extends Equatable {
  const TkBodyScanInputs({
    required this.sex,
    required this.ageInYears,
    required this.heightInCm,
    required this.weightInKg,
    required this.ethnicity,
    this.isSmoker = false,
    this.hasHypertension = false,
    this.diabetesStatus = 'non_diabetic',
  });
  final TkBiologicalSex sex;
  final num heightInCm;
  final num weightInKg;
  final int ageInYears;
  final TkEthnicityType ethnicity;
  final bool isSmoker;
  final bool hasHypertension;
  final String diabetesStatus; // 'non_diabetic', 'type_1', 'type_2', 'prediabetic'

  Map<String, dynamic> asOptionsMap({bool debug = false}) {
    return <String, dynamic>{
      'enum_ent_sex': sex.toLabel(),
      'cm_ent_height': heightInCm,
      'kg_ent_weight': weightInKg,
      'yr_ent_age': ageInYears,
      'bool_ent_smoker': isSmoker,
      'bool_ent_hypertension': hasHypertension,
      'enum_ent_diabetes': diabetesStatus,
      'debug_isDebug': debug
    };
  }

  static TkBodyScanInputs fromHealthData(
    TkUserDataMutable userData, {
    bool? isSmoker,
    bool? hasHypertension,
    String? diabetesStatus,
  }) {
    return TkBodyScanInputs(
      sex: userData.biologicalSex ?? TkBiologicalSex.BS_MALE,
      heightInCm: (userData.heightInCm ?? 170.0).clamp(50, 255),
      weightInKg: (userData.weightInKg ?? 70.0).clamp(16, 300),
      ageInYears: userData.age ?? 20,
      ethnicity: userData.ethnicityType ?? TkEthnicityType.WHITE,
      isSmoker: isSmoker ?? false,
      hasHypertension: hasHypertension ?? false,
      diabetesStatus: diabetesStatus ?? 'non_diabetic',
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[sex, heightInCm, weightInKg, ageInYears, ethnicity, isSmoker, hasHypertension, diabetesStatus];
}

class TkBodyScanResultData extends Equatable {
  TkBodyScanResultData({
    this.dbKey,
    required this.scanDate,
    required this.json,
    required this.inputs,
  });

  final String? dbKey;
  final DateTime scanDate;
  final Map<String, dynamic> json;
  final TkBodyScanInputs inputs;
  String? meshPath;

  // Body measurements
  num? get chestInCm => json['cm_adj_chest'] ?? json['cm_raw_chest'];
  num? get waistInCm => json['cm_adj_waist'] ?? json['cm_raw_waist'];
  num? get hipsInCm => json['cm_adj_hips'] ?? json['cm_raw_hips'];
  num? get thighInCm => json['cm_adj_thigh'] ?? json['cm_raw_thigh'];
  num? get inseamInCm => json['cm_adj_inseam'] ?? json['cm_raw_inseam'];

  // Body composition
  num? get bodyfatInPercent => json['percent_adj_bodyFat'] ?? json['percent_raw_bodyFat'];
  num? get weightPredictInKg => json['kg_adj_weightPredict'] ?? json['kg_raw_weightPredict'];
  
  // Computed values
  num? get muscleMassInKg => weightPredictInKg != null && bodyfatInPercent != null
      ? weightPredictInKg! * (1 - bodyfatInPercent! / 100)
      : null;
  num? get fatMassInKg => weightPredictInKg != null && bodyfatInPercent != null
      ? weightPredictInKg! * (bodyfatInPercent! / 100)
      : null;

  // Health ratios
  num? get waistToHeightRatio => waistInCm != null && inputs.heightInCm > 0
      ? waistInCm! / inputs.heightInCm
      : null;
  num? get waistToHipRatio => waistInCm != null && hipsInCm != null && hipsInCm! > 0
      ? waistInCm! / hipsInCm!
      : null;

  // User info
  String get biologicalSex => inputs.sex.toLabel();
  num get heightInCm => inputs.heightInCm;
  num get weightInKg => inputs.weightInKg;
  int get ageInYears => inputs.ageInYears;

  // Raw measurements
  num? get rawChestInCm => json['cm_raw_chest'];
  num? get rawWaistInCm => json['cm_raw_waist'];
  num? get rawBodyfatPercent => json['percent_raw_bodyFat'];

  @override
  List<Object?> get props => <Object?>[json, inputs];
}