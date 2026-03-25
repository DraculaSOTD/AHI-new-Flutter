import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/profile_service.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String _gender = 'male';
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();
  final _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    // Initialize ProfileService and check if profile exists
    _checkAndNavigate();
  }

  Future<void> _checkAndNavigate() async {
    // Initialize ProfileService to load data from storage
    await _profileService.initialize();

    // Check if profile exists after initialization
    if (mounted && _profileService.hasSelectedProfile) {
      // Profile exists, skip this screen and go directly to body scan
      // Use pushReplacement to prevent back navigation to this screen
      context.pushReplacement('/scan/body/preparation');
    }
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    if (_formKey.currentState!.validate()) {
      context.push('/scan/body/preparation');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Information',
                        style: AppTypography.headingSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please provide accurate information for better results',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Gender selection
              Text(
                'Gender',
                style: AppTypography.bodyLarge.copyWith(
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
                      onChanged: (value) {
                        setState(() {
                          _gender = value!;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Female'),
                      value: 'female',
                      groupValue: _gender,
                      onChanged: (value) {
                        setState(() {
                          _gender = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Age input
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  hintText: 'Enter your age',
                  suffixText: 'years',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your age';
                  }
                  final age = int.tryParse(value);
                  if (age == null || age < 13 || age > 120) {
                    return 'Please enter a valid age (13-120)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Height input
              TextFormField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Height',
                  hintText: 'Enter your height',
                  suffixText: 'cm',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your height';
                  }
                  final height = double.tryParse(value);
                  if (height == null || height < 100 || height > 250) {
                    return 'Please enter a valid height (100-250 cm)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Weight input
              TextFormField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Weight',
                  hintText: 'Enter your weight',
                  suffixText: 'kg',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your weight';
                  }
                  final weight = double.tryParse(value);
                  if (weight == null || weight < 30 || weight > 300) {
                    return 'Please enter a valid weight (30-300 kg)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: AppDimensions.buttonHeightLarge,
                child: ElevatedButton(
                  onPressed: _handleContinue,
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}