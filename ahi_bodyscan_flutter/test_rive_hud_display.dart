import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'lib/features/face_scan/widgets/rive_hud_overlay.dart';

void main() {
  testWidgets('Rive HUD displays with proper aspect ratio', (WidgetTester tester) async {
    print('\n🎨 Testing Rive HUD Display');
    print('=' * 50);
    
    // Test on different screen sizes
    final screenSizes = [
      const Size(375, 812),  // iPhone X/11/12/13 mini
      const Size(390, 844),  // iPhone 12/13/14
      const Size(428, 926),  // iPhone 12/13/14 Pro Max
      const Size(360, 640),  // Older Android
      const Size(412, 915),  // Pixel 6
      const Size(768, 1024), // iPad mini
    ];
    
    for (var screenSize in screenSizes) {
      print('\n📱 Testing on screen: ${screenSize.width} x ${screenSize.height}');
      print('  Aspect ratio: ${(screenSize.height / screenSize.width).toStringAsFixed(2)}');
      
      // Set test screen size
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;
      
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Container(color: Colors.black),
                const RiveHUDOverlay(
                  haloState: 0,
                  guideText: 'Place your face in the outline',
                  contextText: 'Make sure your face is well lit',
                  bpmValue: '--',
                  completionStates: {},
                ),
              ],
            ),
          ),
        ),
      );
      
      await tester.pump();
      
      // Verify the widget builds without errors
      expect(find.byType(RiveHUDOverlay), findsOneWidget);
      
      // Check if FittedBox is properly configured
      final fittedBox = tester.widget<FittedBox>(
        find.byType(FittedBox).first,
      );
      expect(fittedBox.fit, BoxFit.cover, 
        reason: 'FittedBox should use cover to fill screen');
      expect(fittedBox.alignment, Alignment.center,
        reason: 'FittedBox should be centered');
      
      print('  ✅ HUD displays correctly');
    }
    
    // Reset to default
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    
    print('\n✅ All screen sizes tested successfully!');
  });
}