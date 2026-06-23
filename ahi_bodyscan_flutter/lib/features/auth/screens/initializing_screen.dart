import '../../../core/services/logging_service.dart';
import '../../../core/services/permission_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class InitializingScreen extends StatefulWidget {
  const InitializingScreen({super.key});

  @override
  State<InitializingScreen> createState() => _InitializingScreenState();
}

class _InitializingScreenState extends State<InitializingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
    ));

    _animationController.forward();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Global error handler to prevent unhandled exceptions
    try {
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // Retry mechanism for SharedPreferences in case plugin channels aren't ready
      SharedPreferences? prefs;
      int retryCount = 0;
      const maxRetries = 5; // Increased from 3 to 5

      while (prefs == null && retryCount < maxRetries) {
        try {
          LoggingService.info('Attempting to get SharedPreferences', tag: 'InitializingScreen', context: {'attempt': retryCount + 1, 'maxRetries': maxRetries});
          prefs = await SharedPreferences.getInstance();
          LoggingService.success('SharedPreferences obtained successfully', tag: 'InitializingScreen');
        } catch (e) {
          retryCount++;
          LoggingService.warning('SharedPreferences retry failed', tag: 'InitializingScreen', context: {'retryCount': retryCount, 'maxRetries': maxRetries, 'error': e.toString()});
          if (retryCount < maxRetries) {
            // Wait before retrying (exponential backoff)
            final delayMs = 500 * retryCount;
            LoggingService.info('Waiting before retry', tag: 'InitializingScreen', context: {'delayMs': delayMs});
            await Future.delayed(Duration(milliseconds: delayMs));
          } else {
            // If all retries fail, throw to outer catch
            throw Exception('SharedPreferences initialization failed after $maxRetries attempts: $e');
          }
        }
      }

      if (!mounted || prefs == null) {
        LoggingService.warning('Widget unmounted or prefs null - aborting navigation', tag: 'InitializingScreen');
        return;
      }

      final isAuthenticated = prefs.getBool('isAuthenticated') ?? false;
      final termsAccepted = prefs.getBool('termsAccepted') ?? false;

      LoggingService.info('Auth status', tag: 'InitializingScreen', context: {'authenticated': isAuthenticated, 'termsAccepted': termsAccepted});

      // Proactively request every runtime permission the app needs on first
      // open. Best-effort and never throws, so navigation below is unaffected
      // by the user's choices. Already-granted permissions are silent no-ops.
      await PermissionService.requestStartupPermissions();

      if (!mounted) return;

      if (isAuthenticated && termsAccepted) {
        LoggingService.info('Navigating to /home', tag: 'InitializingScreen');
        context.go('/home');
      } else if (isAuthenticated && !termsAccepted) {
        LoggingService.info('Navigating to /terms', tag: 'InitializingScreen');
        context.go('/terms');
      } else {
        LoggingService.info('Navigating to /login', tag: 'InitializingScreen');
        context.go('/login');
      }
    } catch (e, stackTrace) {
      // Catch any unhandled exceptions to prevent blank screen
      LoggingService.error('Fatal error in _checkAuthStatus', error: e, tag: 'InitializingScreen');
      LoggingService.debug('Stack trace', tag: 'InitializingScreen', context: {'stackTrace': stackTrace.toString()});

      // Fallback: always navigate to login screen on any error
      if (mounted) {
        LoggingService.warning('Fallback - navigating to /login due to error', tag: 'InitializingScreen');
        context.go('/login');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundWhite,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.health_and_safety,
                          size: 60,
                          color: AppColors.primaryPurple,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'AHI BodyScan',
                        style: AppTypography.headingLarge.copyWith(
                          color: AppColors.textWhite,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Advanced Health Intelligence',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textWhite.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 48),
                      const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.backgroundWhite,
                          ),
                          strokeWidth: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}