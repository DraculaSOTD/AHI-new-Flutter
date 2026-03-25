import '../../../core/services/logging_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = 'v${packageInfo.version}';
    });
  }

  /// Safely save authentication data to SharedPreferences with retry logic
  /// Returns true if saved successfully, false otherwise
  Future<bool> _saveAuthData(String email) async {
    const maxRetries = 3;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        LoggingService.info('Attempting to save auth data', tag: 'LoginScreen', context: {'attempt': attempt, 'maxRetries': maxRetries});
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isAuthenticated', true);
        await prefs.setString('userEmail', email);
        LoggingService.success('Auth data saved successfully', tag: 'LoginScreen');
        return true;
      } catch (e) {
        LoggingService.warning('Failed to save auth data', tag: 'LoginScreen', context: {'attempt': attempt, 'maxRetries': maxRetries, 'error': e.toString()});
        if (attempt < maxRetries) {
          await Future.delayed(Duration(milliseconds: 300 * attempt));
        }
      }
    }

    // If all retries failed, log warning but allow app to continue
    LoggingService.warning('SharedPreferences failed - continuing without persistence', tag: 'LoginScreen', context: {'maxRetries': maxRetries});
    LoggingService.warning('Session will not persist across app restarts', tag: 'LoginScreen');
    return false;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // Save auth status (with retry logic)
      await _saveAuthData(_emailController.text);

      if (!mounted) return;

      // Navigate to terms (even if SharedPreferences failed)
      context.go('/terms');
    } catch (e) {
      LoggingService.error('Login error', error: e, tag: 'LoginScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      // Always clear loading state
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundWhite,
              AppColors.backgroundLight,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // Logo and title
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [AppShadows.large],
                        ),
                        child: const Icon(
                          Icons.health_and_safety,
                          size: 50,
                          color: AppColors.textWhite,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Welcome Back',
                        style: AppTypography.headingLarge.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to continue',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                // Login form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'Enter your email',
                          prefixIcon: const Icon(Icons.email_outlined),
                          filled: true,
                          fillColor: AppColors.backgroundWhite,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: AppColors.backgroundWhite,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // TODO: Implement forgot password
                          },
                          child: Text(
                            'Forgot Password?',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.primaryPurple,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Login button
                      SizedBox(
                        width: double.infinity,
                        height: AppDimensions.buttonHeightLarge,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryPurple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusPill,
                              ),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.textWhite,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Sign In',
                                  style: AppTypography.buttonLarge.copyWith(
                                    color: AppColors.textWhite,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Divider
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Demo login button
                      SizedBox(
                        width: double.infinity,
                        height: AppDimensions.buttonHeightLarge,
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  setState(() {
                                    _isLoading = true;
                                  });

                                  try {
                                    // Save auth status (with retry logic)
                                    await _saveAuthData('demo@ahi.com');

                                    if (!mounted) return;

                                    // Navigate to terms (even if SharedPreferences failed)
                                    context.go('/terms');
                                  } catch (e) {
                                    LoggingService.error('Demo login error', error: e, tag: 'LoginScreen');
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Demo login failed: ${e.toString()}'),
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                    }
                                  } finally {
                                    // Always clear loading state
                                    if (mounted) {
                                      setState(() {
                                        _isLoading = false;
                                      });
                                    }
                                  }
                                },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.primaryPurple,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusPill,
                              ),
                            ),
                          ),
                          child: Text(
                            'Continue with Demo Account',
                            style: AppTypography.buttonMedium.copyWith(
                              color: AppColors.primaryPurple,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Sign up link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // TODO: Implement sign up
                            },
                            child: Text(
                              'Sign Up',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.primaryPurple,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Version display
                      if (_appVersion.isNotEmpty)
                        Center(
                          child: Text(
                            _appVersion,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}