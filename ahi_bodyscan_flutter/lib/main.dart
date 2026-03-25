import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'core/services/ahi_sdk_service.dart';
import 'core/services/logging_service.dart';
import 'src/ahi_turnkey_services/ahi_app_init_service.dart';
import 'features/health_assessment/services/health_assessment_orchestrator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize app configuration
  try {
    LoggingService.info('Loading environment configuration', tag: 'AppInit');
    await AppConfig.initialize();
    LoggingService.success('Configuration loaded successfully', tag: 'AppInit');
    LoggingService.info('Environment', tag: 'AppInit', context: {'environment': AppConfig.environment});
  } catch (e) {
    LoggingService.error('Failed to load configuration', error: e, tag: 'AppInit');
    LoggingService.info('Make sure you have copied .env.example to .env and filled in the credentials', tag: 'AppInit');
    // Exit app if configuration fails - this is critical
    throw Exception('App configuration failed: $e');
  }

  // Initialize Rive
  await RiveFile.initialize();

  // Pre-initialize SharedPreferences to ensure platform channel is ready
  // This prevents "channel-error" exceptions when widgets try to access it
  try {
    LoggingService.info('Pre-initializing SharedPreferences', tag: 'AppInit');
    await SharedPreferences.getInstance();
    LoggingService.success('SharedPreferences platform channel ready', tag: 'AppInit');
  } catch (e) {
    LoggingService.warning('SharedPreferences pre-initialization failed: $e', tag: 'AppInit');
    LoggingService.info('App will retry during screen initialization', tag: 'AppInit');
  }

  // Initialize AHI Native SDK (legacy)
  try {
    LoggingService.info('Initializing legacy AHI Native SDK', tag: 'AppInit');
    await AHISDKService.initializeSDK();
    LoggingService.success('Legacy AHI Native SDK ready', tag: 'AppInit');
  } catch (e) {
    LoggingService.error('Failed to initialize legacy AHI Native SDK', error: e, tag: 'AppInit');
    // Continue app launch even if SDK fails to initialize
  }

  // Initialize AHI Turnkey services
  try {
    LoggingService.info('Initializing AHI Turnkey services', tag: 'AppInit');
    final initSuccess = await AHIAppInitService().initializeApp();
    if (initSuccess) {
      LoggingService.success('AHI Turnkey services ready', tag: 'AppInit');
      final status = AHIAppInitService().getInitializationStatus();
      LoggingService.debug('AHI Status', tag: 'AppInit', context: {'status': status});
    } else {
      LoggingService.warning('AHI Turnkey initialization incomplete - using mock data', tag: 'AppInit');
    }
  } catch (e) {
    LoggingService.error('Failed to initialize AHI Turnkey services', error: e, tag: 'AppInit');
    // Continue app launch - scans will use mock data
  }
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HealthAssessmentOrchestrator()),
      ],
      child: const AHIBodyScanApp(),
    ),
  );
}

class AHIBodyScanApp extends StatelessWidget {
  const AHIBodyScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AHI BodyScan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: AppRouter.router,
    );
  }
}