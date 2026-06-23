import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/user_profile.dart';
import '../../../services/profile_service.dart';
import '../../../core/utils/date_utils.dart';

class ProfileEditorScreen extends StatefulWidget {
  final UserProfile? profile;
  final bool isCreating;

  const ProfileEditorScreen({
    super.key,
    this.profile,
    this.isCreating = false,
  });

  @override
  State<ProfileEditorScreen> createState() => _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends State<ProfileEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProfileService _profileService = ProfileService();
  
  // Form controllers
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightFeetController = TextEditingController();
  final _heightInchesController = TextEditingController();
  
  // Form state
  String _gender = 'male';
  DateTime? _dateOfBirth;
  String _heightUnit = 'cm';
  String _weightUnit = 'kg';
  String _exerciseLevel = 'inactive';
  String _chronicMedication = 'none';
  String _smokingStatus = 'never';
  String _diabetesStatus = 'no';
  String _hasHypertension = 'no';
  String _takingBPMedication = 'no';
  String _familyHistoryCardiovascular = 'no';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.profile != null) {
      _populateForm(widget.profile!);
    }
  }

  void _populateForm(UserProfile profile) {
    _nameController.text = profile.name;
    _gender = profile.gender;
    _dateOfBirth = DateTime.tryParse(profile.dateOfBirth);
    _heightController.text = profile.height.toString();
    _weightController.text = profile.weight.toString();
    _heightUnit = profile.heightUnit;
    _weightUnit = profile.weightUnit;
    _heightFeetController.text = profile.heightFeet ?? '';
    _heightInchesController.text = profile.heightInches ?? '';
    _exerciseLevel = profile.exerciseLevel;
    _chronicMedication = profile.chronicMedication;
    _smokingStatus = profile.smokingStatus;
    _diabetesStatus = profile.diabetesStatus;
    _hasHypertension = profile.hasHypertension;
    _takingBPMedication = profile.takingBPMedication;
    _familyHistoryCardiovascular = profile.familyHistoryCardiovascular;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _heightFeetController.dispose();
    _heightInchesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateOfBirth == null) {
      _showError('Please select your date of birth');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final profile = UserProfile(
        id: widget.profile?.id ?? '',
        name: _nameController.text.trim(),
        gender: _gender,
        dateOfBirth: _dateOfBirth!.toIso8601String().split('T')[0],
        height: double.parse(_heightController.text),
        weight: double.parse(_weightController.text),
        heightUnit: _heightUnit,
        weightUnit: _weightUnit,
        heightFeet: _heightUnit == 'ft' ? _heightFeetController.text : null,
        heightInches: _heightUnit == 'ft' ? _heightInchesController.text : null,
        exerciseLevel: _exerciseLevel,
        chronicMedication: _chronicMedication,
        smokingStatus: _smokingStatus,
        diabetesStatus: _diabetesStatus,
        hasHypertension: _hasHypertension,
        takingBPMedication: _takingBPMedication,
        familyHistoryCardiovascular: _familyHistoryCardiovascular,
        isMainProfile: widget.profile?.isMainProfile ?? false,
        createdAt: widget.profile?.createdAt ?? DateTime.now(),
        lastUpdated: DateTime.now(),
      );

      // Validate profile
      if (!_profileService.validateProfile(profile)) {
        final errors = _profileService.getProfileValidationErrors(profile);
        _showError('Validation failed:\n${errors.join('\n')}');
        return;
      }

      UserProfile savedProfile;
      if (widget.isCreating) {
        savedProfile = await _profileService.createProfile(profile);
        _showSuccess('Profile created successfully');
      } else {
        savedProfile = await _profileService.updateProfile(profile);
        _showSuccess('Profile updated successfully');
      }

      if (mounted) {
        context.pop(savedProfile);
      }
    } catch (e) {
      _showError('Failed to save profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(widget.isCreating ? 'Create Profile' : 'Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      color: AppColors.primaryPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          // Bake the system gesture-nav inset into the bottom padding so the
          // "Create / Update Profile" button isn't hidden under the nav bar
          // when the form is fully scrolled.
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.viewPaddingOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information Section
              _buildSectionHeader('Basic Information'),
              const SizedBox(height: 16),
              
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name*',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Gender selection
              Text(
                'Gender*',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Male'),
                      value: 'male',
                      groupValue: _gender,
                      onChanged: (value) => setState(() => _gender = value!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Female'),
                      value: 'female',
                      groupValue: _gender,
                      onChanged: (value) => setState(() => _gender = value!),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Date of birth
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.grey[600]),
                      const SizedBox(width: 12),
                      Text(
                        _dateOfBirth == null
                            ? 'Date of Birth*'
                            : AppDateUtils.formatDate(_dateOfBirth!),
                        style: TextStyle(
                          color: _dateOfBirth == null ? Colors.grey[600] : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Physical Information Section
              _buildSectionHeader('Physical Information'),
              const SizedBox(height: 16),
              
              // Height section
              Row(
                children: [
                  Text(
                    'Height Unit:',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _heightUnit,
                    onChanged: (value) => setState(() => _heightUnit = value!),
                    items: const [
                      DropdownMenuItem(value: 'cm', child: Text('Centimeters')),
                      DropdownMenuItem(value: 'ft', child: Text('Feet & Inches')),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              if (_heightUnit == 'cm') ...[
                TextFormField(
                  controller: _heightController,
                  decoration: InputDecoration(
                    labelText: 'Height (cm)*',
                    prefixIcon: const Icon(Icons.height),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Height is required';
                    }
                    final height = double.tryParse(value);
                    if (height == null || height <= 0) {
                      return 'Please enter a valid height';
                    }
                    if (height < 100 || height > 250) {
                      return 'Height must be between 100-250 cm';
                    }
                    return null;
                  },
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _heightFeetController,
                        decoration: InputDecoration(
                          labelText: 'Feet*',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          final feet = double.tryParse(value);
                          if (feet == null || feet <= 0) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _heightInchesController,
                        decoration: InputDecoration(
                          labelText: 'Inches',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final inches = double.tryParse(value);
                            if (inches == null || inches < 0 || inches >= 12) {
                              return 'Invalid';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Weight section
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      decoration: InputDecoration(
                        labelText: 'Weight*',
                        prefixIcon: const Icon(Icons.fitness_center),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Weight is required';
                        }
                        final weight = double.tryParse(value);
                        if (weight == null || weight <= 0) {
                          return 'Please enter a valid weight';
                        }
                        final minWeight = _weightUnit == 'kg' ? 30 : 66;
                        final maxWeight = _weightUnit == 'kg' ? 300 : 660;
                        if (weight < minWeight || weight > maxWeight) {
                          return 'Weight must be between $minWeight-$maxWeight ${_weightUnit}';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _weightUnit,
                    onChanged: (value) => setState(() => _weightUnit = value!),
                    items: const [
                      DropdownMenuItem(value: 'kg', child: Text('kg')),
                      DropdownMenuItem(value: 'lbs', child: Text('lbs')),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Health Information Section
              _buildSectionHeader('Health Information'),
              const SizedBox(height: 16),
              
              // Exercise level
              _buildDropdownField(
                'Exercise Level',
                _exerciseLevel,
                [
                  {'value': 'inactive', 'label': 'No exercise'},
                  {'value': 'exercise10Mins', 'label': '10 minutes daily'},
                  {'value': 'exercise20to60Mins', 'label': '20-60 minutes daily'},
                  {'value': 'exercise1to3Hours', 'label': '1-3 hours daily'},
                  {'value': 'exerciseOver3Hours', 'label': 'Over 3 hours daily'},
                ],
                (value) => setState(() => _exerciseLevel = value),
              ),
              
              const SizedBox(height: 16),
              
              // Chronic medication
              _buildDropdownField(
                'Chronic Medication',
                _chronicMedication,
                [
                  {'value': 'none', 'label': 'None'},
                  {'value': 'yes', 'label': 'Yes'},
                ],
                (value) => setState(() => _chronicMedication = value),
              ),
              
              const SizedBox(height: 16),
              
              // Smoking status
              _buildDropdownField(
                'Smoking Status',
                _smokingStatus,
                [
                  {'value': 'never', 'label': 'Never smoked'},
                  {'value': 'former', 'label': 'Former smoker'},
                  {'value': 'current', 'label': 'Current smoker'},
                ],
                (value) => setState(() => _smokingStatus = value),
              ),
              
              const SizedBox(height: 16),
              
              // Diabetes status
              _buildDropdownField(
                'Diabetes',
                _diabetesStatus,
                [
                  {'value': 'no', 'label': 'No'},
                  {'value': 'yes', 'label': 'Yes'},
                ],
                (value) => setState(() => _diabetesStatus = value),
              ),
              
              const SizedBox(height: 16),
              
              // Hypertension
              _buildDropdownField(
                'Hypertension',
                _hasHypertension,
                [
                  {'value': 'no', 'label': 'No'},
                  {'value': 'yes', 'label': 'Yes'},
                ],
                (value) => setState(() => _hasHypertension = value),
              ),
              
              const SizedBox(height: 16),
              
              // Blood pressure medication
              _buildDropdownField(
                'Taking BP Medication',
                _takingBPMedication,
                [
                  {'value': 'no', 'label': 'No'},
                  {'value': 'yes', 'label': 'Yes'},
                ],
                (value) => setState(() => _takingBPMedication = value),
              ),

              const SizedBox(height: 16),

              // Family history of cardiovascular disease
              _buildDropdownField(
                'Family History of Cardiovascular Disease',
                _familyHistoryCardiovascular,
                [
                  {'value': 'no', 'label': 'No'},
                  {'value': 'yes', 'label': 'Yes'},
                ],
                (value) => setState(() => _familyHistoryCardiovascular = value),
              ),

              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(widget.isCreating ? 'Create Profile' : 'Update Profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTypography.headingSmall.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String value,
    List<Map<String, String>> options,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            onChanged: (newValue) => onChanged(newValue!),
            items: options.map((option) {
              return DropdownMenuItem<String>(
                value: option['value'],
                child: Text(option['label']!),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}