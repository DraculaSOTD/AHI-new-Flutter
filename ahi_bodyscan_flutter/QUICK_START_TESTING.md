# Quick Start: Testing Body Scan on Your Phone

## Your Build is Running!

The app is currently being built for your Samsung phone (R5CW21RS60N). This process includes:

✅ Phone authorized for debugging
✅ Flutter dependencies downloaded
✅ Gradle build in progress (downloading AHI SDK...)

**Expected build time**: 5-10 minutes (first build)

## What's Happening Now

1. **Gradle is downloading dependencies**:
   - AHI MultiScan SDK from S3 repository
   - Android support libraries
   - Flutter engine for Android
   - Total download: ~200-300 MB

2. **Compiling the app**:
   - Kotlin/Java code compilation
   - Dart code compilation
   - Native library integration
   - APK assembly

## After Build Completes

### Installation

Your APK will be located at:
```
build/app/outputs/flutter-apk/app-debug.apk
```

**Install on phone**:
```bash
# Option 1: Auto-install (recommended)
flutter install

# Option 2: Manual install via ADB
adb install build/app/outputs/flutter-apk/app-debug.apk

# Option 3: Transfer to phone and install manually
# Copy APK to phone and tap to install
```

### First Launch Steps

1. **Grant Permissions**:
   - When prompted, allow Camera access
   - Allow Storage access
   - Allow Network access (for ML model download)

2. **Wait for SDK Initialization**:
   - First launch takes 1-2 minutes
   - SDK downloads ML models (~54 MB)
   - Watch for "SDK initialized successfully" message

3. **Navigate to Body Scan**:
   - Look for Body Scan button on home screen
   - Or navigate through the app menu

## Testing Body Scan

### Requirements for Good Scan

**Environment**:
- Good lighting (natural daylight preferred)
- Plain background (solid color wall)
- Enough space (6-8 feet from phone to you)

**Positioning**:
- Stand straight, arms slightly away from body
- Face the camera directly
- Ensure full body is visible
- Keep phone at chest height

**Clothing**:
- Wear form-fitting clothes
- Or minimal clothing (shorts/sports bra)
- Avoid loose/baggy clothing for accuracy

### Scan Process

1. **Setup**:
   - Position phone on stable surface or tripod
   - Ensure camera is at your chest level
   - Stand 6-8 feet away

2. **Front View Capture**:
   - Follow on-screen guidance
   - Keep body within the outline
   - Stay still when capturing
   - Wait for automatic capture

3. **Side View Capture**:
   - Turn 90 degrees to your right
   - Keep same distance from camera
   - Follow on-screen positioning
   - Wait for automatic capture

4. **Processing**:
   - Wait 30-60 seconds for processing
   - ML models analyze your images
   - Measurements calculated

5. **Results**:
   - View body measurements
   - See body composition analysis
   - Check BHA (health assessment) if available

## Troubleshooting

### Build Issues

**Error: "AHI SDK not found"**
```bash
# Check credentials
cat android/gradle.properties | grep ahi
# Should show your Maven credentials
```

**Error: "Execution failed for task"**
```bash
# Clean and rebuild
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk --debug
```

### Installation Issues

**Error: "Installation failed"**
```bash
# Uninstall old version first
adb uninstall com.example.ahi_bodyscan_flutter
# Then install again
adb install build/app/outputs/flutter-apk/app-debug.apk
```

**Error: "INSTALL_FAILED_INSUFFICIENT_STORAGE"**
- Free up at least 500 MB on your phone
- Delete unused apps or files

### Runtime Issues

**App crashes on launch**
```bash
# Check logs
adb logcat | grep -i flutter
# Or
adb logcat | grep -i ahi
```

**SDK initialization fails**
- Check internet connection
- Verify token hasn't expired (valid until Nov 5, 2025)
- Check phone has 100+ MB free storage

**Resources won't download**
- Ensure stable internet connection
- Check firewall/VPN not blocking
- Wait and retry (may be temporary network issue)

**Camera won't start**
- Go to phone Settings → Apps → AHI BodyScan
- Check Camera permission is granted
- Restart app after granting permission

### Scan Quality Issues

**Measurements seem inaccurate**
- Improve lighting (add more light sources)
- Use plain background (avoid patterns)
- Wear tighter fitting clothes
- Ensure full body visible in frame
- Keep phone perfectly vertical

**Can't complete scan**
- Check positioning guidance on screen
- Ensure phone is stable (not hand-held)
- Verify good lighting
- Try in different location/time of day

## Expected Results

### Body Measurements

You should receive:
- **Circumferences**: Chest, waist, hip, thigh, inseam
- **Body Composition**: Body fat %, fat-free mass, visceral fat
- **Weight Prediction**: Estimated weight from measurements

### Accuracy

- Circumferences: ±2-3 cm
- Body fat %: ±3-5%
- Best accuracy with optimal conditions

### BHA Health Assessment

If available, you'll also get:
- Cardiovascular risk assessment
- Metabolic health score
- Body composition analysis
- Fitness level evaluation
- Personalized recommendations

## Development Mode Features

**Hot Reload**: Make code changes and see them instantly
```bash
# Instead of flutter build, use:
flutter run --debug
# Then press 'r' to hot reload after code changes
```

**Debug Logs**: See real-time console output
```bash
flutter logs
```

**Performance**: Debug builds are slower than release builds
- First scan may take longer
- UI may be less smooth
- More battery consumption

## Next Steps After Successful Test

1. **Verify all features work**:
   - Body scan completes successfully
   - Results are accurate and displayed
   - BHA assessment works
   - Data saves correctly

2. **Test edge cases**:
   - Poor lighting conditions
   - Different clothing types
   - Various backgrounds
   - Different phone positions

3. **Build release version** (for distribution):
   ```bash
   flutter build apk --release
   # APK at: build/app/outputs/flutter-apk/app-release.apk
   ```

4. **Performance testing**:
   - Test on low-end device
   - Test with poor network
   - Test offline mode (after initial download)

## Quick Commands Reference

```bash
# Check connected devices
adb devices

# Install app
flutter install

# View logs
flutter logs

# Uninstall app
adb uninstall com.example.ahi_bodyscan_flutter

# Take screenshot
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png

# Clear app data
adb shell pm clear com.example.ahi_bodyscan_flutter

# Restart app
adb shell am start -n com.example.ahi_bodyscan_flutter/.MainActivity
```

## Support

If you encounter issues:

1. Check build logs: `/tmp/flutter_build.log`
2. Check device logs: `adb logcat`
3. Review AHI SDK setup: `AHI_SDK_SETUP_GUIDE.md`
4. Contact AHI support: support@ahi.tech

---

**Your build is currently in progress. Check back in a few minutes!**

To monitor progress:
```bash
tail -f /tmp/flutter_build.log
```
