import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'core/services/ahi_sdk_service.dart';
import 'core/services/logging_service.dart';
import 'src/ahi_turnkey_services/ahi_app_init_service.dart';
import 'features/health_assessment/services/health_assessment_orchestrator.dart';

// Bumped on every meaningful code change so the user can confirm via
// `adb logcat -s flutter` exactly which build is on the device. If this string
// doesn't appear in logcat on app launch, the running APK is stale.
const String kBuildMarker = 'bodyscan-deep-log-v16';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  LoggingService.info('App build marker', tag: 'AppBoot', context: {
    'buildId': kBuildMarker,
    'launchedAt': DateTime.now().toIso8601String(),
  });

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

  // Required so MediaQuery.padding / viewPadding report the real system insets
  // on Android 15+ edge-to-edge (targetSdk 36). Without this Flutter zeroes
  // them inside Scaffold body and SafeArea-based layouts ignore the nav bar.
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: SystemUiOverlay.values,
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

class AHIBodyScanApp extends StatefulWidget {
  const AHIBodyScanApp({super.key});

  @override
  State<AHIBodyScanApp> createState() => _AHIBodyScanAppState();
}

class _AHIBodyScanAppState extends State<AHIBodyScanApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Keep the screen on for the entire time the app is in the foreground —
    // the assessment and scans are long-running and must not be interrupted by
    // the device locking/dimming. Best-effort; never blocks app launch.
    _enableWakelock();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // The OS keep-screen-on flag only applies to the foreground window and some
    // OEMs drop it across background/foreground transitions — re-assert on
    // resume so the screen never starts sleeping after returning to the app.
    if (state == AppLifecycleState.resumed) {
      _enableWakelock();
    }
  }

  Future<void> _enableWakelock() async {
    try {
      await WakelockPlus.enable();
    } catch (e) {
      LoggingService.warning('Wakelock enable failed',
          tag: 'AHIBodyScanApp', context: {'error': e.toString()});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

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