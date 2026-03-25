# Build, Install & Test Guide - AHI Body Scan App

## Build Status

✅ **Phone Connected**: Samsung (R5CW21RS60N) - Authorized
✅ **Flutter Dependencies**: Downloaded
✅ **Compilation Errors**: Fixed
⏳ **Build In Progress**: Check `/tmp/flutter_build3.log` for status

## Once Build Completes Successfully

### Step 1: Verify Build Success

Check build log:
```bash
tail -50 /tmp/flutter_build3.log
```

Look for:
```
✓ Built build/app/outputs/flutter-apk/app-debug.apk (XXX MB)
```

### Step 2: Install on Your Phone

**Option A: Direct Install (Recommended)**
```bash
cd "/home/calvin/Websites/AHI-new Flutter/ahi_bodyscan_flutter"
flutter install
```

**Option B: Manual ADB Install**
```bash
adb install build/app/outputs/flutter-apk/app-debug.apk
```

**Option C: Transfer and Install**
```bash
# Transfer APK to phone
adb push build/app/outputs/flutter-apk/app-debug.apk /sdcard/Download/

# Then on your phone:
# 1. Open Files app
# 2. Go to Downloads folder
# 3. Tap app-debug.apk
# 4. Allow "Install from unknown sources" if prompted
# 5. Tap Install
```

### Step 3: Launch the App

From your phone:
1. Find "AHI BodyScan Flutter" in app drawer
2. Tap to open

Or from terminal:
```bash
adb shell am start -n com.example.ahi_bodyscan_flutter/.MainActivity
```

### Step 4: Grant Permissions

When app launches, grant these permissions:
- ✅ Camera (Required for body scanning)
- ✅ Storage (For saving scan results)
- ✅ Network (For downloading ML models)

### Step 5: SDK Initialization

On first launch:
1. **Wait 1-2 minutes** for AHI SDK to initialize
2. SDK will download ML models (~54 MB)
3. Watch for progress indicator or "SDK Ready" message
4. **Keep phone connected to WiFi** during first launch

To monitor initialization:
```bash
# In terminal, watch logs
flutter logs

# Or filter for AHI SDK messages
adb logcat | grep -i "AHI SDK"
```

## Testing Body Scan Feature

### Prerequisites

**Environment Setup**:
- Good lighting (natural daylight is best)
- Plain solid-color background
- Clear space (6-8 feet in front of phone)
- Stable surface to place phone

**Clothing**:
- Form-fitting clothes (tight shirt, shorts/leggings)
- OR minimal clothing (sports bra, shorts for better accuracy)
- Avoid loose/baggy clothing

**Phone Setup**:
- Place phone on stable surface (NOT hand-held)
- Camera at your chest height
- Phone in portrait orientation
- Ensure phone won't move during scan

### Step-by-Step Scan Process

#### 1. Navigate to Body Scan
- Open app
- Look for "Body Scan" button or feature
- Tap to start

#### 2. Enter Your Profile Information
If prompted:
- Height: Enter in cm (e.g., 170)
- Weight: Enter in kg (e.g., 70)
- Age: Your age in years
- Gender: Select male/female
- Save profile

#### 3. Position Yourself - Front View
- Stand 6-8 feet from phone
- Face camera directly
- Arms slightly away from body (not touching sides)
- Stand upright, shoulders relaxed
- **Keep entire body visible** (head to ankles)

Follow on-screen guidance:
- Green outline = good positioning
- Red outline = adjust position
- Instructions will tell you what to adjust

#### 4. Front Capture
- When positioned correctly, phone will beep
- **Stay perfectly still** for 2-3 seconds
- Camera will automatically capture

#### 5. Position Yourself - Side View
- Turn 90 degrees to your right
- Same distance from phone (6-8 feet)
- Arms slightly away from body
- Stand upright
- **Keep entire body visible in frame**

#### 6. Side Capture
- Same as front: wait for beep
- Stay still for 2-3 seconds
- Auto-capture

#### 7. Processing
- Wait 30-60 seconds
- ML models analyze your images
- Don't close app during processing

#### 8. View Results
You should see:
- **Body Measurements**:
  - Chest circumference
  - Waist circumference
  - Hip circumference
  - Thigh circumference
  - Inseam length

- **Body Composition** (if available):
  - Body fat percentage
  - Fat-free mass percentage
  - Visceral fat level
  - Weight prediction

- **BHA Health Assessment** (if enabled):
  - Overall health score
  - Cardiovascular risk
  - Metabolic health
  - Personalized recommendations

### Expected Results Accuracy

With good conditions:
- Circumferences: ±2-3 cm
- Body fat %: ±3-5%
- Best with optimal lighting and positioning

### Common Issues & Solutions

#### App crashes on launch
```bash
# Check logs
adb logcat | grep -E "(flutter|AndroidRuntime)"

# Clear app data and retry
adb shell pm clear com.example.ahi_bodyscan_flutter
```

#### SDK initialization fails
- **Check internet connection**
- **Wait longer** (first init can take 2-3 minutes)
- **Check storage** (need 200+ MB free)
- Check logs for error messages

#### Camera won't start
```bash
# Verify camera permission
adb shell dumpsys package com.example.ahi_bodyscan_flutter | grep "android.permission.CAMERA"

# Should show: granted=true
```

If not granted:
- Go to Settings → Apps → AHI BodyScan → Permissions
- Enable Camera permission
- Restart app

#### Poor scan results/Can't complete scan
- **Improve lighting**: Add more light sources
- **Change background**: Use solid color wall
- **Adjust distance**: Try 7 feet exactly
- **Better clothing**: Wear tighter fitting clothes
- **Phone stability**: Ensure phone is perfectly stable
- **Try different room**: Some rooms have better lighting

#### Processing takes too long
- Normal: 30-60 seconds
- Long: 1-2 minutes if phone is slow
- If >3 minutes: Check logs for errors

#### No results displayed
- Check if processing completed
- Look for error messages in logs
- Verify scan actually captured (check saved images if feature exists)

## Monitoring & Debugging

### Real-time Logs
```bash
# See all app logs
flutter logs

# Filter for errors only
adb logcat | grep -E "(E/flutter|E/AndroidRuntime)"

# Filter for AHI SDK messages
adb logcat | grep -i "ahi"

# Save logs to file
adb logcat > /tmp/app_logs.txt
```

### Check App State
```bash
# Is app running?
adb shell ps | grep ahi_bodyscan

# App storage usage
adb shell du -sh /data/data/com.example.ahi_bodyscan_flutter

# List app files
adb shell run-as com.example.ahi_bodyscan_flutter ls -la
```

### Screenshots During Testing
```bash
# Take screenshot
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png ./

# Record screen video
adb shell screenrecord /sdcard/test_scan.mp4
# ... do your test ...
# Press Ctrl+C to stop
adb pull /sdcard/test_scan.mp4 ./
```

## Performance Tips

### For Best Results:
1. **First scan takes longest** (ML models loading)
2. **Subsequent scans faster** (models cached)
3. **Keep app in memory** (don't force-close between tests)
4. **Stable internet** (for first-time resource download)
5. **充足 storage** (keep 500MB+ free)

### Debug vs Release Performance:
- **Debug build** (current): Slower, more battery use
- **Release build**: 2-3x faster, optimized

To build release version later:
```bash
flutter build apk --release
```

## Testing Checklist

- [ ] App installs successfully
- [ ] Permissions granted (Camera, Storage, Network)
- [ ] SDK initializes (watch logs for "SDK initialized successfully")
- [ ] Resources download (ML models ~54MB)
- [ ] Can create/select user profile
- [ ] Can start body scan
- [ ] Front view capture works
- [ ] Side view capture works
- [ ] Processing completes
- [ ] Results display correctly
- [ ] Measurements seem reasonable
- [ ] BHA assessment works (if enabled)
- [ ] Can save scan results
- [ ] Can view past scans

## Next Steps After Successful Test

1. **Document any issues** encountered
2. **Take screenshots** of results
3. **Note measurement accuracy** vs real measurements
4. **Test multiple times** for consistency
5. **Try different conditions** (lighting, clothing, etc.)
6. **Test other features** (Face scan, Finger scan if available)
7. **Build release version** for better performance
8. **Consider UX improvements** based on testing

## Quick Commands Reference

```bash
# Build
flutter build apk --debug

# Install
flutter install

# Uninstall
adb uninstall com.example.ahi_bodyscan_flutter

# Logs
flutter logs

# Clear data
adb shell pm clear com.example.ahi_bodyscan_flutter

# Launch app
adb shell am start -n com.example.ahi_bodyscan_flutter/.MainActivity

# Check connected devices
adb devices

# Kill and restart adb
adb kill-server && adb start-server
```

## Support

If you encounter issues:
1. Check logs first: `flutter logs` or `adb logcat`
2. Review error messages carefully
3. Check [QUICK_START_TESTING.md](QUICK_START_TESTING.md) for troubleshooting
4. Review [AHI_SDK_SETUP_GUIDE.md](AHI_SDK_SETUP_GUIDE.md) for SDK issues

---

**Ready to test! Follow the steps above once your build completes.**

Current build status: Check `/tmp/flutter_build3.log`
