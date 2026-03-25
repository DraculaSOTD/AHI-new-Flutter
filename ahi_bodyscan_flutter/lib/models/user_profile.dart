import 'dart:convert';

class UserProfile {
  final String id;
  final String name;
  final String gender;
  final String dateOfBirth;
  final double height;
  final double weight;
  final String heightUnit; // 'cm' or 'ft'
  final String weightUnit; // 'kg' or 'lbs'
  final String? heightFeet;
  final String? heightInches;
  
  // Health questionnaire fields
  final String exerciseLevel;
  final String chronicMedication;
  final String smokingStatus;
  final String diabetesStatus;
  final String hasHypertension;
  final String takingBPMedication;
  final String familyHistoryCardiovascular;
  
  // Profile metadata
  final bool isMainProfile;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final String? profilePicture;
  
  // Calculated fields
  int get age {
    final birthDate = DateTime.tryParse(dateOfBirth);
    if (birthDate == null) return 0;
    
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }
  
  // Compatibility aliases for AHI integration
  int get ageInYears => age;
  String get biologicalSex => gender;
  
  double get heightInCm {
    if (heightUnit == 'ft' && heightFeet != null) {
      final feet = double.tryParse(heightFeet!) ?? 0;
      final inches = double.tryParse(heightInches ?? '0') ?? 0;
      return (feet * 30.48) + (inches * 2.54);
    }
    return height;
  }
  
  double get weightInKg {
    if (weightUnit == 'lbs') {
      return weight * 0.453592;
    }
    return weight;
  }
  
  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  UserProfile({
    required this.id,
    required this.name,
    required this.gender,
    required this.dateOfBirth,
    required this.height,
    required this.weight,
    this.heightUnit = 'cm',
    this.weightUnit = 'kg',
    this.heightFeet,
    this.heightInches,
    this.exerciseLevel = 'inactive',
    this.chronicMedication = 'none',
    this.smokingStatus = 'never',
    this.diabetesStatus = 'no',
    this.hasHypertension = 'no',
    this.takingBPMedication = 'no',
    this.familyHistoryCardiovascular = 'no',
    this.isMainProfile = false,
    required this.createdAt,
    required this.lastUpdated,
    this.profilePicture,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    String? gender,
    String? dateOfBirth,
    double? height,
    double? weight,
    String? heightUnit,
    String? weightUnit,
    String? heightFeet,
    String? heightInches,
    String? exerciseLevel,
    String? chronicMedication,
    String? smokingStatus,
    String? diabetesStatus,
    String? hasHypertension,
    String? takingBPMedication,
    String? familyHistoryCardiovascular,
    bool? isMainProfile,
    DateTime? createdAt,
    DateTime? lastUpdated,
    String? profilePicture,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      heightUnit: heightUnit ?? this.heightUnit,
      weightUnit: weightUnit ?? this.weightUnit,
      heightFeet: heightFeet ?? this.heightFeet,
      heightInches: heightInches ?? this.heightInches,
      exerciseLevel: exerciseLevel ?? this.exerciseLevel,
      chronicMedication: chronicMedication ?? this.chronicMedication,
      smokingStatus: smokingStatus ?? this.smokingStatus,
      diabetesStatus: diabetesStatus ?? this.diabetesStatus,
      hasHypertension: hasHypertension ?? this.hasHypertension,
      takingBPMedication: takingBPMedication ?? this.takingBPMedication,
      familyHistoryCardiovascular: familyHistoryCardiovascular ?? this.familyHistoryCardiovascular,
      isMainProfile: isMainProfile ?? this.isMainProfile,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      profilePicture: profilePicture ?? this.profilePicture,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'height': height,
      'weight': weight,
      'heightUnit': heightUnit,
      'weightUnit': weightUnit,
      'heightFeet': heightFeet,
      'heightInches': heightInches,
      'exerciseLevel': exerciseLevel,
      'chronicMedication': chronicMedication,
      'smokingStatus': smokingStatus,
      'diabetesStatus': diabetesStatus,
      'hasHypertension': hasHypertension,
      'takingBPMedication': takingBPMedication,
      'familyHistoryCardiovascular': familyHistoryCardiovascular,
      'isMainProfile': isMainProfile,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'profilePicture': profilePicture,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      gender: json['gender'] ?? 'male',
      dateOfBirth: json['dateOfBirth'] ?? '',
      height: (json['height'] ?? 170.0).toDouble(),
      weight: (json['weight'] ?? 70.0).toDouble(),
      heightUnit: json['heightUnit'] ?? 'cm',
      weightUnit: json['weightUnit'] ?? 'kg',
      heightFeet: json['heightFeet'],
      heightInches: json['heightInches'],
      exerciseLevel: json['exerciseLevel'] ?? 'inactive',
      chronicMedication: json['chronicMedication'] ?? 'none',
      smokingStatus: json['smokingStatus'] ?? 'never',
      diabetesStatus: json['diabetesStatus'] ?? 'no',
      hasHypertension: json['hasHypertension'] ?? 'no',
      takingBPMedication: json['takingBPMedication'] ?? 'no',
      familyHistoryCardiovascular: json['familyHistoryCardiovascular'] ?? 'no',
      isMainProfile: json['isMainProfile'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      lastUpdated: DateTime.tryParse(json['lastUpdated'] ?? '') ?? DateTime.now(),
      profilePicture: json['profilePicture'],
    );
  }

  String toJsonString() => json.encode(toJson());

  factory UserProfile.fromJsonString(String jsonString) {
    return UserProfile.fromJson(json.decode(jsonString));
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, name: $name, age: $age, gender: $gender)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Validation methods
  bool get isValid {
    return name.isNotEmpty &&
           gender.isNotEmpty &&
           dateOfBirth.isNotEmpty &&
           height > 0 &&
           weight > 0;
  }

  List<String> get validationErrors {
    final errors = <String>[];
    
    if (name.isEmpty) errors.add('Name is required');
    if (gender.isEmpty) errors.add('Gender is required');
    if (dateOfBirth.isEmpty) errors.add('Date of birth is required');
    if (height <= 0) errors.add('Valid height is required');
    if (weight <= 0) errors.add('Valid weight is required');
    
    // Validate height ranges
    final heightCm = heightInCm;
    if (heightCm < 100 || heightCm > 250) {
      errors.add('Height must be between 100-250 cm');
    }
    
    // Validate weight ranges
    final weightKg = weightInKg;
    if (weightKg < 30 || weightKg > 300) {
      errors.add('Weight must be between 30-300 kg');
    }
    
    // Validate age
    if (age < 13 || age > 120) {
      errors.add('Age must be between 13-120 years');
    }
    
    return errors;
  }

  // Create a default profile for testing/demo
  factory UserProfile.defaultProfile() {
    return UserProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Main Profile',
      gender: 'male',
      dateOfBirth: DateTime(1990, 1, 1).toIso8601String().split('T')[0],
      height: 175.0,
      weight: 70.0,
      heightUnit: 'cm',
      weightUnit: 'kg',
      exerciseLevel: 'exercise20to60Mins',
      chronicMedication: 'none',
      smokingStatus: 'never',
      diabetesStatus: 'no',
      hasHypertension: 'no',
      takingBPMedication: 'no',
      familyHistoryCardiovascular: 'no',
      isMainProfile: true,
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
    );
  }
}