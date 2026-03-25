import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Auth screens
import '../../features/auth/screens/initializing_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/terms_of_service_screen.dart';

// Main screens
import '../../features/home/screens/home_screen.dart';
import '../../features/scanning/screens/new_scan_screen.dart';
import '../../features/scanning/screens/user_profile_screen.dart';
import '../../features/reports/screens/reports_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/profile_editor_screen.dart';
import '../../models/user_profile.dart';

// Face scan screens
import '../../features/face_scan/screens/face_scan_preparation_screen.dart';
import '../../features/face_scan/screens/face_scan_camera_screen.dart';
import '../../features/face_scan/screens/face_scan_results_screen.dart';
import '../../services/lambda_service.dart';

// Body scan screens
import '../../features/body_scan/screens/body_scan_preparation_screen.dart';
import '../../features/body_scan/screens/body_scan_screen.dart';

// Health assessment screens
import '../../features/health_assessment/screens/health_assessment_disclaimer_screen.dart';
import '../../features/health_assessment/screens/anxiety_survey_screen.dart';
import '../../features/health_assessment/screens/depression_survey_screen.dart';
import '../../features/health_assessment/screens/fitness_screening_questionnaire_screen.dart';
import '../../features/health_assessment/screens/fitness_step_test_preparation_screen.dart';
import '../../features/health_assessment/screens/fitness_step_test_active_screen.dart';
import '../../features/health_assessment/screens/health_assessment_summary_screen.dart';

// Navigation shell for bottom nav
import '../../shared/widgets/main_navigation_shell.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    // Redirect logic removed - InitializingScreen handles navigation based on auth state
    // This prevents race conditions with SharedPreferences during router initialization
    routes: [
      // Initial route
      GoRoute(
        path: '/',
        builder: (context, state) => const InitializingScreen(),
      ),
      
      // Auth routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsOfServiceScreen(),
      ),
      
      // Main navigation shell
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainNavigationShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/reports',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ReportsScreen(),
            ),
          ),
          GoRoute(
            path: '/new-scan',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: NewScanScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),
      
      // Profile routes (outside shell for full screen)
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/profile/create',
        builder: (context, state) => const ProfileEditorScreen(isCreating: true),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) {
          final profile = state.extra as UserProfile?;
          return ProfileEditorScreen(profile: profile, isCreating: false);
        },
      ),
      GoRoute(
        path: '/profiles',
        builder: (context, state) => const ProfileScreen(),
      ),
      
      // Scan flow routes
      GoRoute(
        path: '/scan/user-profile',
        builder: (context, state) => const UserProfileScreen(),
      ),
      
      // Body scan routes
      GoRoute(
        path: '/scan/body/preparation',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return BodyScanPreparationScreen(
            isPartOfAssessment: extra?['isPartOfAssessment'] as bool? ?? false,
          );
        },
      ),
      GoRoute(
        path: '/scan/body/camera',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return BodyScanScreen(
            isPartOfAssessment: extra?['isPartOfAssessment'] as bool? ?? false,
          );
        },
      ),
      
      // Face scan routes
      GoRoute(
        path: '/scan/face/preparation',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return FaceScanPreparationScreen(
            isPartOfAssessment: extra?['isPartOfAssessment'] as bool? ?? false,
          );
        },
      ),
      GoRoute(
        path: '/scan/face/camera',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return FaceScanCameraScreen(
            isPartOfAssessment: extra?['isPartOfAssessment'] as bool? ?? false,
          );
        },
      ),
      GoRoute(
        path: '/scan/face/results',
        builder: (context, state) {
          final extra = state.extra;
          // Handle both Map format and direct HealthAssessmentResult format
          if (extra is Map<String, dynamic>) {
            return FaceScanResultsScreen(
              results: extra['results'] as HealthAssessmentResult?,
              isPartOfAssessment: extra['isPartOfAssessment'] as bool? ?? false,
            );
          } else {
            // Backward compatibility: extra is HealthAssessmentResult directly
            return FaceScanResultsScreen(
              results: extra as HealthAssessmentResult?,
              isPartOfAssessment: false,
            );
          }
        },
      ),

      // Health Assessment Flow routes
      GoRoute(
        path: '/health-assessment/disclaimer',
        builder: (context, state) => const HealthAssessmentDisclaimerScreen(),
      ),
      GoRoute(
        path: '/health-assessment/anxiety',
        builder: (context, state) => const AnxietySurveyScreen(),
      ),
      GoRoute(
        path: '/health-assessment/depression',
        builder: (context, state) => const DepressionSurveyScreen(),
      ),
      GoRoute(
        path: '/health-assessment/fitness-screening',
        builder: (context, state) => const FitnessScreeningQuestionnaireScreen(),
      ),
      GoRoute(
        path: '/health-assessment/step-test-prep',
        builder: (context, state) => const FitnessStepTestPreparationScreen(),
      ),
      GoRoute(
        path: '/health-assessment/step-test-active',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return FitnessStepTestActiveScreen(
            stepHeightCm: extra?['stepHeightCm'] as double? ?? 20.0,
          );
        },
      ),
      GoRoute(
        path: '/health-assessment/summary',
        builder: (context, state) => const HealthAssessmentSummaryScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
}