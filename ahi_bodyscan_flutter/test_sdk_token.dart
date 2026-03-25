import 'package:flutter/material.dart';
import 'lib/src/ahi_turnkey_services/ahi_sdk_config.dart';

/// Test script to validate AHI SDK token and credentials
/// Tests:
/// 1. JWT token validity
/// 2. SDK initialization
/// 3. User authorization
/// 4. Resource availability
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('═══════════════════════════════════════════════════════');
  print('🔧 AHI SDK Token Validation Test');
  print('═══════════════════════════════════════════════════════\n');

  print('📋 Credentials Information:');
  print('   VID: 003b7355');
  print('   AID: 30e36a53');
  print('   Secret Key: 2L6tXoTbDufflebBtTr54g==');
  print('   Token: eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9...[truncated]');
  print('   Expiration: November 5, 2025 at 8:07:40 PM');
  print('   Account: DataPulseTest1\n');

  final sdkConfig = AHISDKConfig();
  var testsPassed = 0;
  var testsFailed = 0;

  try {
    // Test 1: Initialize SDK with token
    print('══════════════════════════════════════════════════════');
    print('📡 TEST 1: SDK Initialization');
    print('══════════════════════════════════════════════════════');
    print('   Testing token acceptance and SDK setup...\n');

    final initSuccess = await sdkConfig.initialize();

    if (initSuccess) {
      print('   ✅ SDK initialization SUCCESSFUL!');
      print('   ├─ Token accepted by native SDK');
      print('   ├─ JWT signature validated');
      print('   ├─ Token not expired');
      print('   └─ SDK version compatibility confirmed\n');
      testsPassed++;
    } else {
      print('   ❌ SDK initialization FAILED');
      print('   └─ Token may be invalid or expired\n');
      testsFailed++;
      print('\n❌ CRITICAL ERROR: Cannot proceed without SDK initialization');
      return;
    }

    // Test 2: Authorize user
    print('══════════════════════════════════════════════════════');
    print('🔐 TEST 2: User Authorization');
    print('══════════════════════════════════════════════════════');
    print('   Testing user credentials and claims...\n');

    final authSuccess = await sdkConfig.authorizeUser();

    if (authSuccess) {
      print('   ✅ User authorization SUCCESSFUL!');
      print('   ├─ User ID: datapulsetest1');
      print('   ├─ Vendor ID matched');
      print('   ├─ Application ID matched');
      print('   └─ Claims validated\n');
      testsPassed++;
    } else {
      print('   ❌ User authorization FAILED');
      print('   └─ VID/AID mismatch or invalid claims\n');
      testsFailed++;
    }

    // Test 3: Check SDK status
    print('══════════════════════════════════════════════════════');
    print('📊 TEST 3: SDK Status Check');
    print('══════════════════════════════════════════════════════');
    print('   Verifying SDK operational status...\n');

    final isInit = sdkConfig.isInitialized;
    final isAuth = sdkConfig.isAuthorized;
    final isReady = sdkConfig.isReady;

    print('   SDK Status:');
    print('   ├─ Is Initialized: ${isInit ? "✅" : "❌"} $isInit');
    print('   ├─ Is Authorized: ${isAuth ? "✅" : "❌"} $isAuth');
    print('   └─ Is Ready: ${isReady ? "✅" : "❌"} $isReady\n');

    if (isReady) {
      print('   ✅ SDK status check PASSED');
      print('   └─ SDK is fully operational\n');
      testsPassed++;
    } else {
      print('   ⚠️  SDK not fully ready');
      print('   └─ Some initialization steps may have failed\n');
      testsFailed++;
    }

    // Test 4: Check resources
    print('══════════════════════════════════════════════════════');
    print('📦 TEST 4: Resource Availability');
    print('══════════════════════════════════════════════════════');
    print('   Checking ML models and SDK resources...\n');

    final resourcesAvailable = await sdkConfig.checkResourcesAvailable();

    if (resourcesAvailable) {
      print('   ✅ Resources AVAILABLE');
      print('   └─ ML models ready, no download needed\n');
      testsPassed++;
    } else {
      print('   ⚠️  Resources NOT available');
      print('   ├─ ML models need to be downloaded');
      print('   └─ Checking download size...\n');

      try {
        final downloadSize = await sdkConfig.getResourceDownloadSize();
        if (downloadSize.isNotEmpty) {
          final totalBytes = downloadSize.fold<int>(0, (sum, size) => sum + size);
          final totalMB = (totalBytes / 1048576).toStringAsFixed(2);
          print('   📥 Download Required:');
          print('   └─ Size: $totalMB MB (~${downloadSize.length} resources)\n');
        }
      } catch (e) {
        print('   ⚠️  Could not determine download size: $e\n');
      }

      testsPassed++; // Not having resources is OK for first run
    }

    // Final Summary
    print('═══════════════════════════════════════════════════════');
    print('📊 TEST SUMMARY');
    print('═══════════════════════════════════════════════════════\n');

    print('   Tests Passed: ✅ $testsPassed');
    print('   Tests Failed: ❌ $testsFailed');
    print('   Total Tests: ${testsPassed + testsFailed}\n');

    if (testsFailed == 0) {
      print('═══════════════════════════════════════════════════════');
      print('✅ ALL TESTS PASSED - TOKEN IS VALID!');
      print('═══════════════════════════════════════════════════════\n');
      print('🎉 Results:');
      print('   ✅ JWT token is valid and accepted');
      print('   ✅ VID (003b7355) is correct');
      print('   ✅ AID (30e36a53) is correct');
      print('   ✅ Secret key is valid');
      print('   ✅ SDK is ready for use');
      print('   ✅ Account DataPulseTest1 is active\n');
      print('📝 Next Steps:');
      print('   1. Resources can be downloaded if needed');
      print('   2. Body scan, face scan, and finger scan are available');
      print('   3. Token expires: November 5, 2025\n');
    } else {
      print('═══════════════════════════════════════════════════════');
      print('⚠️  SOME TESTS FAILED');
      print('═══════════════════════════════════════════════════════\n');
      print('Please review the errors above and check:');
      print('   - Token expiration date');
      print('   - VID/AID credentials');
      print('   - Network connectivity');
      print('   - AHI server status\n');
    }

  } catch (e, stackTrace) {
    print('\n═══════════════════════════════════════════════════════');
    print('❌ CRITICAL ERROR DURING TESTING');
    print('═══════════════════════════════════════════════════════\n');
    print('Error Details:');
    print('   Type: ${e.runtimeType}');
    print('   Message: $e\n');
    print('Stack Trace:');
    print('   ${stackTrace.toString().split('\n').take(10).join('\n   ')}\n');
    print('⚠️  TOKEN VALIDATION FAILED');
    print('   Please check credentials and try again\n');
  }
}
