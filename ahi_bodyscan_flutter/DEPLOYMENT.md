# Production Deployment Checklist

This document provides a comprehensive checklist for deploying the AHI BodyScan Flutter application to production.

## Pre-Deployment Checklist

### 1. Environment Configuration

- [ ] **Create production `.env` file**
  ```bash
  cp .env.example .env
  ```

- [ ] **Set production credentials in `.env`**
  ```properties
  AHI_SDK_TOKEN=<production-token>
  VASTMINDZ_WEBSOCKET_URL=wss://vm-production.xyz/vp/bgr_signal_socket
  VASTMINDZ_AUTH_TOKEN=<production-token>
  ENVIRONMENT=production
  ```

- [ ] **Verify `.env` is in `.gitignore`**
  ```bash
  grep "^\.env$" .gitignore
  ```

- [ ] **Test environment loading**
  - Run app and verify configuration loads without errors
  - Check debug console for "✅ Configuration loaded successfully"

### 2. Android Release Signing

- [ ] **Generate release keystore** (if not already done)
  ```bash
  keytool -genkey -v -keystore ~/ahi-release-keystore.jks \
    -keyalg RSA -keysize 2048 -validity 10000 -alias ahi-release
  ```

- [ ] **Create `android/key.properties`**
  ```bash
  cp android/key.properties.example android/key.properties
  ```

- [ ] **Configure signing credentials in `key.properties`**
  ```properties
  storePassword=<your-store-password>
  keyPassword=<your-key-password>
  keyAlias=ahi-release
  storeFile=<absolute-path-to-keystore.jks>
  ```

- [ ] **Verify `key.properties` is in `.gitignore`**
  ```bash
  grep "key.properties" android/.gitignore
  ```

- [ ] **Secure keystore backup**
  - Store keystore file in secure location
  - Document passwords in secure password manager
  - Create encrypted backup

### 3. Package Configuration

- [ ] **Verify package name** in `android/app/build.gradle.kts`
  ```kotlin
  applicationId = "tech.ahi.bodyscan"
  ```

- [ ] **Verify version code and name** in `android/app/build.gradle.kts`
  ```kotlin
  versionCode = flutter.versionCode
  versionName = flutter.versionName
  ```

- [ ] **Update version in `pubspec.yaml`**
  ```yaml
  version: 1.0.0+1  # format: version+build_number
  ```

### 4. SDK Credentials Validation

- [ ] **Test AHI SDK token**
  - Launch app and navigate to body scan
  - Verify SDK initializes without errors
  - Complete a test body scan

- [ ] **Test Vastmindz SDK credentials**
  - Launch app and navigate to face scan
  - Verify WebSocket connection succeeds
  - Complete a test face scan

- [ ] **Verify no hardcoded credentials remain**
  ```bash
  # Search for potential hardcoded tokens
  grep -r "Bearer " lib/ --exclude-dir=.git
  grep -r "eyJ" lib/ --exclude-dir=.git
  grep -r "wss://" lib/ --exclude-dir=.git
  ```

### 5. Code Quality and Security

- [ ] **Remove all debug/test code**
  - No `print()` statements in production code
  - Remove unused imports
  - Remove commented-out code blocks

- [ ] **Verify no mock data** (except demo login)
  ```bash
  # Check for mock/test files
  find lib/ -name "*mock*" -o -name "*test*" -o -name "*dummy*"
  ```

- [ ] **Review demo account configuration**
  - Verify demo credentials are intentional
  - Consider if demo account should be disabled in production

- [ ] **Security audit**
  - [ ] No API keys in source code
  - [ ] No sensitive user data logged
  - [ ] Proper error handling (no stack traces shown to users)
  - [ ] HTTPS/WSS only for network communication

### 6. UI/UX Verification

- [ ] **Test on multiple devices**
  - Various screen sizes (small, medium, large)
  - Different Android versions (26+)

- [ ] **Bottom navigation bar fix verified**
  - No content hidden behind bottom navigation
  - All modals/dialogs display correctly

- [ ] **Profile data integration verified**
  - Selected profile data used in scans
  - Health data (smoking, diabetes, hypertension) correctly passed to SDK

- [ ] **Error handling**
  - Network errors gracefully handled
  - SDK errors display user-friendly messages
  - Profile validation errors clear and actionable

### 7. Performance Optimization

- [ ] **Enable code obfuscation** (optional, may affect crash reporting)
  ```bash
  flutter build apk --release --obfuscate --split-debug-info=build/debug-info
  ```

- [ ] **Analyze app size**
  ```bash
  flutter build apk --release --analyze-size
  ```

- [ ] **Test app performance**
  - No significant lag during navigation
  - Scans complete in expected timeframe
  - Memory usage within acceptable limits

### 8. Build Configuration

- [ ] **Verify `build.gradle.kts` settings**
  ```kotlin
  minSdk = 26
  targetSdk = 36
  compileSdk = 36
  ndkVersion = "27.0.12077973"
  ```

- [ ] **Check packaging options**
  - OpenCV library conflict resolution configured
  - Vastmindz rppg libraries excluded (to prevent crashes)

- [ ] **Verify ProGuard/R8 rules** (if using)
  - Ensure SDK classes are not stripped
  - Test release build thoroughly

## Build Process

### Build Release APK

```bash
# Clean previous builds
flutter clean
flutter pub get

# Build release APK
flutter build apk --release

# Output location:
# build/app/outputs/flutter-apk/app-release.apk
```

### Build App Bundle (for Google Play)

```bash
# Clean previous builds
flutter clean
flutter pub get

# Build App Bundle
flutter build appbundle --release

# Output location:
# build/app/outputs/bundle/release/app-release.aab
```

### Verify Build

- [ ] **Install release APK on test device**
  ```bash
  adb install build/app/outputs/flutter-apk/app-release.apk
  ```

- [ ] **Test all critical paths**
  - [ ] Login with demo account
  - [ ] Create new profile
  - [ ] Complete body scan
  - [ ] Complete face scan
  - [ ] View scan results
  - [ ] Navigate all main screens

- [ ] **Check crash reporting**
  - Ensure crashes are reported to your analytics platform
  - Test error scenarios

## Post-Build Verification

### 1. APK Analysis

```bash
# Analyze APK size and contents
flutter analyze build/app/outputs/flutter-apk/app-release.apk
```

- [ ] **Verify APK size** is reasonable (< 150 MB)
- [ ] **Check native libraries included**
  ```bash
  unzip -l app-release.apk | grep ".so"
  ```

### 2. Security Scan

- [ ] **Run security analysis**
  ```bash
  # If you have security tools, run them here
  # Example: MobSF, QARK, etc.
  ```

- [ ] **Verify no sensitive data in APK**
  ```bash
  # Extract and search APK
  unzip app-release.apk -d apk-extracted
  grep -r "password\|secret\|token" apk-extracted/
  ```

### 3. Store Listing Preparation

- [ ] **Prepare app screenshots**
  - Phone: 16:9 or 9:16 ratio
  - Tablet: Multiple orientations
  - All required screen sizes

- [ ] **Write/update app description**
  - Clear feature list
  - Privacy policy link
  - Terms of service link

- [ ] **Prepare feature graphic**
  - 1024 x 500 pixels
  - Professional design

- [ ] **Privacy policy**
  - Hosted on accessible URL
  - Covers all data collection
  - SDK data usage disclosed

## Deployment Steps

### Google Play Store

1. [ ] **Create release in Play Console**
2. [ ] **Upload App Bundle** (`app-release.aab`)
3. [ ] **Fill out store listing**
4. [ ] **Set content rating**
5. [ ] **Add privacy policy URL**
6. [ ] **Configure pricing and distribution**
7. [ ] **Submit for review**

### Alternative Distribution

For enterprise or testing distribution:

1. [ ] **Upload to distribution platform** (Firebase App Distribution, etc.)
2. [ ] **Share with testers**
3. [ ] **Collect feedback**

## Post-Deployment Monitoring

### 1. First 24 Hours

- [ ] Monitor crash reports
- [ ] Check analytics for adoption
- [ ] Review user feedback
- [ ] Monitor SDK API usage

### 2. First Week

- [ ] Analyze user behavior patterns
- [ ] Check for performance issues
- [ ] Review error rates
- [ ] Plan hotfix if critical issues found

### 3. Ongoing

- [ ] Regular dependency updates
- [ ] SDK version updates
- [ ] Security patches
- [ ] Feature releases

## Rollback Plan

If critical issues are discovered:

1. [ ] **Halt rollout** in Play Console (if gradual rollout configured)
2. [ ] **Identify issue** from crash reports/logs
3. [ ] **Fix and rebuild**
4. [ ] **Test thoroughly**
5. [ ] **Re-submit**

## Environment Management

### Development Environment
```properties
ENVIRONMENT=development
# Use development/staging tokens
```

### Production Environment
```properties
ENVIRONMENT=production
# Use production tokens only
```

## Critical Files to Protect

**Never commit these files to version control:**
- `.env` (all variants)
- `android/key.properties`
- `android/gradle.properties` (if contains secrets)
- `*.jks` (keystore files)
- `*.p12` (certificate files)

**Verify with:**
```bash
git status --ignored
```

## Support and Maintenance

### Update SDK Tokens

When tokens need rotation:

1. Update `.env` file
2. Rebuild app
3. Submit new version to store
4. Coordinate with backend team for cutover

### Version Updates

Follow semantic versioning:
- **Major** (1.0.0): Breaking changes
- **Minor** (1.1.0): New features, backward compatible
- **Patch** (1.0.1): Bug fixes

Update in `pubspec.yaml`:
```yaml
version: MAJOR.MINOR.PATCH+BUILD_NUMBER
```

## Contacts

- **AHI SDK Support**: [Contact details]
- **Vastmindz SDK Support**: [Contact details]
- **Development Team**: [Contact details]
- **DevOps/Release Manager**: [Contact details]

---

## Final Checklist Summary

Before submitting to production:

- [x] Environment variables configured
- [x] Release signing configured
- [x] Package name verified (tech.ahi.bodyscan)
- [x] Version numbers updated
- [x] SDK credentials validated
- [x] Security audit passed
- [x] UI/UX tested on multiple devices
- [x] Release build created and tested
- [x] APK/Bundle analyzed
- [x] Store listing prepared
- [x] Monitoring configured
- [x] Rollback plan documented

**Production build date**: ___________
**Build version**: ___________
**Released by**: ___________
**Approved by**: ___________
