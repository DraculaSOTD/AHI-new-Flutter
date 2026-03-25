import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../core/services/logging_service.dart';

class ProfileService extends ChangeNotifier {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  static const String _profilesKey = 'user_profiles';
  static const String _selectedProfileKey = 'selected_profile_id';

  List<UserProfile> _profiles = [];
  UserProfile? _selectedProfile;
  bool _isLoaded = false;

  // Getters
  List<UserProfile> get profiles => List.unmodifiable(_profiles);
  UserProfile? get selectedProfile => _selectedProfile;
  bool get isLoaded => _isLoaded;
  bool get hasProfiles => _profiles.isNotEmpty;
  bool get hasSelectedProfile => _selectedProfile != null;
  UserProfile? get mainProfile => _profiles.where((p) => p.isMainProfile).firstOrNull;

  /// Initialize the service and load profiles
  Future<void> initialize() async {
    if (_isLoaded) return;
    
    await _loadProfiles();
    await _loadSelectedProfile();
    _isLoaded = true;
    notifyListeners();
  }

  /// Load all profiles from storage
  Future<void> _loadProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profilesJson = prefs.getStringList(_profilesKey) ?? [];
      
      _profiles = profilesJson
          .map((jsonString) => UserProfile.fromJsonString(jsonString))
          .toList();
      
      // Sort profiles: main profile first, then by creation date
      _profiles.sort((a, b) {
        if (a.isMainProfile && !b.isMainProfile) return -1;
        if (!a.isMainProfile && b.isMainProfile) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });
    } catch (e, stackTrace) {
      LoggingService.error(
        'Error loading profiles',
        error: e,
        stackTrace: stackTrace,
        tag: 'ProfileService',
      );
      _profiles = [];
    }
  }

  /// Load the selected profile
  Future<void> _loadSelectedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedId = prefs.getString(_selectedProfileKey);
      
      if (selectedId != null) {
        _selectedProfile = _profiles.where((p) => p.id == selectedId).firstOrNull;
      }
      
      // If no selected profile or selected profile not found, use main profile
      _selectedProfile ??= mainProfile;
      
      // If still no profile, use the first available profile
      _selectedProfile ??= _profiles.firstOrNull;
    } catch (e, stackTrace) {
      LoggingService.error(
        'Error loading selected profile',
        error: e,
        stackTrace: stackTrace,
        tag: 'ProfileService',
      );
      _selectedProfile = null;
    }
  }

  /// Save all profiles to storage
  Future<void> _saveProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profilesJson = _profiles.map((p) => p.toJsonString()).toList();
      await prefs.setStringList(_profilesKey, profilesJson);
    } catch (e, stackTrace) {
      LoggingService.error(
        'Error saving profiles',
        error: e,
        stackTrace: stackTrace,
        tag: 'ProfileService',
      );
      throw Exception('Failed to save profiles');
    }
  }

  /// Save the selected profile ID
  Future<void> _saveSelectedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_selectedProfile != null) {
        await prefs.setString(_selectedProfileKey, _selectedProfile!.id);
      } else {
        await prefs.remove(_selectedProfileKey);
      }
    } catch (e, stackTrace) {
      LoggingService.error(
        'Error saving selected profile',
        error: e,
        stackTrace: stackTrace,
        tag: 'ProfileService',
      );
    }
  }

  /// Create a new profile
  Future<UserProfile> createProfile(UserProfile profile) async {
    // Ensure unique ID
    final newProfile = profile.copyWith(
      id: profile.id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : profile.id,
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
    );

    // If this is the first profile, make it the main profile
    if (_profiles.isEmpty) {
      final mainProfile = newProfile.copyWith(isMainProfile: true);
      _profiles.add(mainProfile);
      _selectedProfile = mainProfile;
    } else {
      _profiles.add(newProfile);
    }

    await _saveProfiles();
    await _saveSelectedProfile();
    notifyListeners();

    return newProfile;
  }

  /// Update an existing profile
  Future<UserProfile> updateProfile(UserProfile updatedProfile) async {
    final index = _profiles.indexWhere((p) => p.id == updatedProfile.id);
    if (index == -1) {
      throw Exception('Profile not found');
    }

    final profile = updatedProfile.copyWith(lastUpdated: DateTime.now());
    _profiles[index] = profile;

    // Update selected profile if it's the one being updated
    if (_selectedProfile?.id == profile.id) {
      _selectedProfile = profile;
    }

    await _saveProfiles();
    await _saveSelectedProfile();
    notifyListeners();

    return profile;
  }

  /// Delete a profile
  Future<void> deleteProfile(String profileId) async {
    final profile = _profiles.where((p) => p.id == profileId).firstOrNull;
    if (profile == null) {
      throw Exception('Profile not found');
    }

    if (profile.isMainProfile) {
      throw Exception('Cannot delete main profile');
    }

    _profiles.removeWhere((p) => p.id == profileId);

    // If the deleted profile was selected, select another one
    if (_selectedProfile?.id == profileId) {
      _selectedProfile = mainProfile ?? _profiles.firstOrNull;
    }

    await _saveProfiles();
    await _saveSelectedProfile();
    notifyListeners();
  }

  /// Select a profile
  Future<void> selectProfile(UserProfile profile) async {
    _selectedProfile = profile;
    await _saveSelectedProfile();
    notifyListeners();
  }

  /// Select a profile by ID
  Future<void> selectProfileById(String profileId) async {
    final profile = _profiles.where((p) => p.id == profileId).firstOrNull;
    if (profile != null) {
      await selectProfile(profile);
    }
  }

  /// Get a profile by ID
  UserProfile? getProfileById(String profileId) {
    return _profiles.where((p) => p.id == profileId).firstOrNull;
  }

  /// Set a profile as main profile
  Future<void> setMainProfile(String profileId) async {
    // Remove main profile status from all profiles
    for (int i = 0; i < _profiles.length; i++) {
      _profiles[i] = _profiles[i].copyWith(isMainProfile: false);
    }

    // Set the new main profile
    final index = _profiles.indexWhere((p) => p.id == profileId);
    if (index != -1) {
      _profiles[index] = _profiles[index].copyWith(
        isMainProfile: true,
        lastUpdated: DateTime.now(),
      );
    }

    await _saveProfiles();
    notifyListeners();
  }

  /// Import profiles from JSON
  Future<void> importProfiles(List<Map<String, dynamic>> profilesData) async {
    final importedProfiles = profilesData
        .map((data) => UserProfile.fromJson(data))
        .where((profile) => profile.isValid)
        .toList();

    for (final profile in importedProfiles) {
      // Check if profile already exists
      if (!_profiles.any((p) => p.id == profile.id)) {
        _profiles.add(profile);
      }
    }

    await _saveProfiles();
    notifyListeners();
  }

  /// Export all profiles to JSON
  List<Map<String, dynamic>> exportProfiles() {
    return _profiles.map((profile) => profile.toJson()).toList();
  }

  /// Clear all profiles (for testing/reset)
  Future<void> clearAllProfiles() async {
    _profiles.clear();
    _selectedProfile = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profilesKey);
    await prefs.remove(_selectedProfileKey);

    notifyListeners();
  }

  /// Create default main profile if no profiles exist
  Future<void> ensureMainProfile() async {
    if (_profiles.isEmpty) {
      final defaultProfile = UserProfile.defaultProfile();
      await createProfile(defaultProfile);
    }
  }

  /// Search profiles by name
  List<UserProfile> searchProfiles(String query) {
    if (query.isEmpty) return profiles;
    
    return _profiles
        .where((profile) => 
            profile.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  /// Get profile statistics
  Map<String, dynamic> getProfileStats() {
    final totalProfiles = _profiles.length;
    final maleCount = _profiles.where((p) => p.gender == 'male').length;
    final femaleCount = _profiles.where((p) => p.gender == 'female').length;
    
    double avgAge = 0;
    if (totalProfiles > 0) {
      avgAge = _profiles.map((p) => p.age).reduce((a, b) => a + b) / totalProfiles;
    }

    return {
      'totalProfiles': totalProfiles,
      'maleCount': maleCount,
      'femaleCount': femaleCount,
      'averageAge': avgAge.round(),
      'hasMainProfile': mainProfile != null,
      'selectedProfileId': _selectedProfile?.id,
    };
  }

  /// Validate profile data before saving
  bool validateProfile(UserProfile profile) {
    return profile.isValid;
  }

  /// Get validation errors for a profile
  List<String> getProfileValidationErrors(UserProfile profile) {
    return profile.validationErrors;
  }
}