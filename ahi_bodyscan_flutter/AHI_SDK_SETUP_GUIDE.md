# AHI SDK Setup Guide - DataPulseTest1

This guide explains how to configure and use the AHI MultiScan SDK with your provided credentials.

## Credentials Overview

Your AHI SDK account credentials:
- **Client Name**: AHI: SDK Access for DataPulseTest1
- **Vendor ID (VID)**: `003b7355`
- **Application ID (AID)**: `30e36a53`
- **Secret Key**: `2L6tXoTbDufflebBtTr54g==`
- **JWT Token**: Configured in `lib/src/ahi_turnkey_services/ahi_sdk_config.dart`

## Configuration Files

### 1. Flutter SDK Configuration
**File**: `lib/src/ahi_turnkey_services/ahi_sdk_config.dart`

Contains:
- JWT authentication token
- Vendor ID and Application ID
- Secret key for SDK encryption
- User authorization claims

### 2. Android Configuration
**File**: `android/gradle.properties`

Contains Maven S3 credentials for accessing AHI SDK repository:
- Access Key: `[REDACTED]`
- Secret Key: `[REDACTED]`

**File**: `android/build.gradle.kts`

Configured with:
- S3 Maven repository URL: `s3://ahi-sdk-maven/release`
- AWS credentials integration
- AHI SDK dependency

### 3. iOS Configuration
**File**: `ios/Podfile`

Contains Git credentials for accessing AHI private CocoaPods repository:
- Username: `t-datapulsetest1-at-175889021455`
- Password: `T4MvfhC9qocV34t8FKmIauqqwy+P9z/Utt5UF1v7WeYIafFpCmoiykhZ+Ug=`
- Git Repository: `git.ahi.tech/sdk/multiscan-ios.git`

## Installation Steps

### Android Setup

1. **Sync Gradle dependencies**:
   ```bash
   cd android
   ./gradlew clean
   ./gradlew --refresh-dependencies
   ```

2. **Verify AHI SDK download**:
   - Check build output for successful SDK download from S3
   - Look for `tech.ahi.sdk:ahi-multiscan:2.2.0` in dependency tree

### iOS Setup

1. **Install CocoaPods dependencies**:
   ```bash
   cd ios
   pod install --repo-update
   ```

2. **Verify AHI SDK installation**:
   - Check for `AHIMultiScanSDK` in Pods directory
   - Verify Git authentication succeeded

## Usage in Flutter

### Initialize SDK

```dart
import 'package:ahi_bodyscan_flutter/src/ahi_turnkey_services/ahi_sdk_config.dart';

// Initialize the SDK
final ahiConfig = AHISDKConfig();
final success = await ahiConfig.setupSDK();

if (success) {
  print('AHI SDK initialized successfully!');
} else {
  print('AHI SDK initialization failed');
}
```

### Check SDK Status

```dart
if (ahiConfig.isReady) {
  // SDK is initialized and user is authorized
  // Ready to perform scans
}
```

### Download Resources

```dart
if (!await ahiConfig.checkResourcesAvailable()) {
  print('Downloading AHI SDK resources...');
  await ahiConfig.downloadResources();
}
```

## Security Best Practices

### ⚠️ **IMPORTANT**: Do NOT commit credentials to version control!

The following files contain sensitive credentials:
- `android/gradle.properties`
- `ios/Podfile`
- `lib/src/ahi_turnkey_services/ahi_sdk_config.dart`

### For Production Deployment:

1. **Use Environment Variables**:
   ```bash
   export AHI_SDK_TOKEN="your-jwt-token"
   export AHI_MAVEN_ACCESS_KEY="your-access-key"
   export AHI_MAVEN_SECRET_KEY="your-secret-key"
   ```

2. **Flutter Build-time Configuration**:
   ```bash
   flutter build apk --dart-define=AHI_SDK_TOKEN=your-token
   ```

3. **Secure Storage**:
   - Store tokens in device keychain (iOS) or KeyStore (Android)
   - Fetch credentials from secure backend server
   - Use Flutter Secure Storage package

### Recommended .gitignore Entries

Add to your `.gitignore`:
```
# AHI SDK Credentials
android/gradle.properties
ios/Podfile
lib/src/ahi_turnkey_services/ahi_sdk_config.dart

# Environment files
.env
.env.local
.env.production
```

## Troubleshooting

### Android Issues

**Problem**: Maven S3 authentication fails
```
Solution: Verify credentials in gradle.properties
Check AWS credentials are correct
Ensure gradle.properties is not in .gitignore
```

**Problem**: AHI SDK not found
```
Solution: Clean and rebuild:
  ./gradlew clean
  ./gradlew --refresh-dependencies
```

### iOS Issues

**Problem**: Pod install fails with authentication error
```
Solution: Verify Git credentials in Podfile
Check GIT_USERNAME and GIT_PASSWORD values
Ensure proper URL escaping for special characters
```

**Problem**: AHIMultiScanSDK pod not found
```
Solution: Check Git repository URL
Verify tag version (2.2.0) exists
Try with specific commit SHA instead of tag
```

## SDK Documentation

For detailed SDK documentation, visit:
- **Developer Portal**: https://www.ahi.tech/portal-content/multiscan-sdk-v22-0-install
- **API Reference**: Available after login to AHI developer portal

## Token Expiration

Your JWT token expires on:
- **Expiration Date**: 2025-11-05 (Unix timestamp: 1762366060)

Before this date, you'll need to:
1. Request a new token from AHI
2. Update `ahi_sdk_config.dart` with the new token
3. Rebuild and redeploy your app

## Support

For AHI SDK support:
- Email: support@ahi.tech
- Developer Portal: https://www.ahi.tech/portal
- Documentation: https://docs.ahi.tech

## Next Steps

1. ✅ Test SDK initialization
2. ✅ Verify resource download
3. ✅ Test body scan functionality
4. ✅ Test face scan functionality
5. ✅ Test finger scan functionality
6. ✅ Implement production credential management
7. ✅ Set up CI/CD with secure environment variables
