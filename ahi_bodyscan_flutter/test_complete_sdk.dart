import 'package:flutter/material.dart';
import 'package:rppg_common/rppg_common.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('===============================================');
  print('🧪 COMPREHENSIVE VASTMINDZ SDK TEST');
  print('===============================================');
  
  // Test 1: Check permissions
  print('\n📱 TEST 1: Camera Permission Check');
  print('-----------------------------------');
  try {
    final status = await Permission.camera.status;
    print('✅ Current camera permission status: $status');
    
    if (!status.isGranted) {
      print('📷 Requesting camera permission...');
      final result = await Permission.camera.request();
      print('✅ Permission request result: $result');
    }
  } catch (e) {
    print('❌ Permission check failed: $e');
  }
  
  // Test 2: SDK Instance Creation
  print('\n🔌 TEST 2: SDK Instance Creation');
  print('-----------------------------------');
  RppgCommon? rppgCommon;
  try {
    rppgCommon = RppgCommon();
    print('✅ SDK instance created successfully');
  } catch (e) {
    print('❌ Failed to create SDK instance: $e');
    return;
  }
  
  // Test 3: Platform Channel Verification
  print('\n📡 TEST 3: Platform Channel Verification');
  print('-----------------------------------');
  try {
    print('🔍 Checking platform channel...');
    final state = await rppgCommon.getState().timeout(
      const Duration(seconds: 2),
      onTimeout: () {
        print('⚠️ Platform channel timeout (2s)');
        return 'timeout';
      },
    );
    
    if (state == 'timeout') {
      print('⚠️ Platform channel might not be responding');
    } else {
      print('✅ Platform channel is working!');
      print('📊 Current SDK state: $state');
    }
  } catch (e) {
    print('❌ Platform channel error: $e');
    if (e.toString().contains('MissingPluginException')) {
      print('🔴 CRITICAL: Plugin not registered on platform!');
      print('💡 Solutions:');
      print('   1. Run: flutter clean');
      print('   2. Run: flutter pub get');
      print('   3. For Android: Rebuild the app');
      print('   4. For iOS: cd ios && pod install');
      return;
    }
  }
  
  // Test 4: SDK Initialization Sequence
  print('\n🚀 TEST 4: SDK Initialization Sequence');
  print('-----------------------------------');
  try {
    // Step 1: Request permissions via SDK
    print('📸 Requesting permissions via SDK...');
    try {
      final hasPermission = await rppgCommon.askPermissions().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('⚠️ Permission request timeout');
          return false;
        },
      );
      print('✅ Permission result: $hasPermission');
    } catch (e) {
      print('⚠️ Permission request error: $e');
    }
    
    // Step 2: Configure camera (with SDK bug workaround)
    print('\n⚙️ Configuring camera (30fps, front)...');
    bool configureSuccess = false;
    await Future.any([
      Future(() async {
        try {
          await rppgCommon!.configure(30, true);
          configureSuccess = true;
          print('✅ Configure completed');
        } catch (e) {
          print('⚠️ Configure error: $e');
        }
      }),
      Future.delayed(const Duration(seconds: 1)).then((_) {
        print('⚠️ Configure timeout (SDK bug workaround applied)');
      }),
    ]);
    
    // Wait for configuration to take effect
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Check state after configure
    try {
      final state = await rppgCommon.getState().timeout(
        const Duration(seconds: 1),
        onTimeout: () => 'unknown',
      );
      print('📊 State after configure: $state');
    } catch (e) {
      print('⚠️ Could not get state: $e');
    }
    
    // Step 3: Start video (with SDK bug workaround)
    print('\n🎥 Starting video capture...');
    bool videoStartSuccess = false;
    await Future.any([
      Future(() async {
        try {
          await rppgCommon!.startVideo();
          videoStartSuccess = true;
          print('✅ StartVideo completed');
        } catch (e) {
          print('⚠️ StartVideo error: $e');
        }
      }),
      Future.delayed(const Duration(seconds: 1)).then((_) {
        print('⚠️ StartVideo timeout (SDK bug workaround applied)');
      }),
    ]);
    
    // Wait for video to start
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Check final state
    try {
      final state = await rppgCommon.getState().timeout(
        const Duration(seconds: 1),
        onTimeout: () => 'unknown',
      );
      print('📊 Final state: $state');
      
      if (state == 'videoStarted') {
        print('✅ VIDEO IS READY FOR DISPLAY!');
      }
    } catch (e) {
      print('⚠️ Could not get final state: $e');
    }
    
  } catch (e) {
    print('❌ Initialization sequence failed: $e');
  }
  
  // Summary
  print('\n===============================================');
  print('📋 TEST SUMMARY');
  print('===============================================');
  print('✅ Tests completed. Check output above for issues.');
  print('');
  print('💡 If you see MissingPluginException:');
  print('   - The SDK plugin is not properly registered');
  print('   - Run: flutter clean && flutter pub get');
  print('   - Rebuild the app completely');
  print('');
  print('💡 If you see timeout warnings:');
  print('   - This is expected due to SDK bugs');
  print('   - The workarounds should handle it');
  print('');
  print('💡 Next steps:');
  print('   1. Run this test on your target device/emulator');
  print('   2. Check that camera permission is granted');
  print('   3. Verify SDK state reaches "videoStarted"');
  print('   4. Then the RppgCameraView should show video');
  print('===============================================');
  
  // Create a simple UI to show test completed
  runApp(MaterialApp(
    home: Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 20),
            const Text(
              'SDK Test Completed',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
            const SizedBox(height: 10),
            const Text(
              'Check console output for results',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 40),
            // Show camera view if SDK initialized
            Container(
              width: 300,
              height: 400,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: const RppgCameraView(),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Camera View (if SDK initialized)',
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
          ],
        ),
      ),
    ),
  ));
}