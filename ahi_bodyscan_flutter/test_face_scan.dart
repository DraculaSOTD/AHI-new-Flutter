import 'package:flutter/material.dart';
import 'package:rppg_common/rppg_common.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('Testing Vastmindz SDK initialization...');
  
  final rppgCommon = RppgCommon();
  
  try {
    // Step 1: Get initial state
    print('Getting SDK state...');
    String state = await rppgCommon.getState();
    print('Initial state: $state');
    
    // Step 2: Request permissions
    if (state == 'initial') {
      print('Requesting permissions...');
      bool hasPermission = await rppgCommon.askPermissions();
      print('Permission granted: $hasPermission');
      
      if (hasPermission) {
        // Step 3: Configure (synchronous)
        print('Configuring camera...');
        rppgCommon.configure(30, true);
        print('Configure called (synchronous)');
        
        // Wait for configuration
        await Future.delayed(Duration(milliseconds: 500));
        
        // Check state
        state = await rppgCommon.getState();
        print('State after configure: $state');
        
        // Step 4: Start video (synchronous)
        if (state == 'prepared') {
          print('Starting video...');
          rppgCommon.startVideo();
          print('StartVideo called (synchronous)');
          
          // Wait for video start
          await Future.delayed(Duration(milliseconds: 500));
          
          // Check final state
          state = await rppgCommon.getState();
          print('State after startVideo: $state');
          
          print('✅ SDK initialization successful!');
        }
      }
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}