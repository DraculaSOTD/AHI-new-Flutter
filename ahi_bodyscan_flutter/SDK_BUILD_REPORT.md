# SDK Example App Build Report
## Date: October 27, 2025

## Executive Summary

**Status**: ❌ **BLOCKED** - SDK source code version mismatch

Attempted to build the AHI MultiScan SDK example app from source code, but encountered version compatibility issues between the SDK source code (v25.2-dev) and available dependencies (v23.11.x).

---

## What Was Attempted

Built the standalone Android SDK example app located at:
`SDK/ahi-sdk-multiscan-android-25.2-dev/ahi-sdk-multiscan-android-25.2-dev/`

### Goals:
1. Build the SDK from source
2. Compile the example/demo app
3. Install on device with Data PulseTest1 credentials
4. Test SDK initialization and scanning with your JWT token

---

## Work Completed ✅

### 1. JWT Token Integration
- ✅ Updated [MainActivity.kt:27](SDK/ahi-sdk-multiscan-android-25.2-dev/ahi-sdk-multiscan-android-25.2-dev/app/src/main/java/com/advancedhumanimaging/sdk/multiscan/example/MainActivity.kt#L27) with your DataPulseTest1 JWT token
- ✅ Token expires: November 5, 2025
- ✅ VID: `003b7355`, AID: `30e36a53`

### 2. Build Configuration Fixed

#### AWS S3 Credentials
- ✅ Configured environment variables:
  - `AHI_RELEASE_AWS_ACCESS_KEY=[REDACTED]`
  - `AHI_RELEASE_AWS_SECRET_KEY=[REDACTED]`
- ✅ Credentials validated - user `arn:aws:iam::175889021455:user/t-datapulsetest1` authenticated successfully
- ✅ Access confirmed to: `s3://ahi-prod-sdk-builds/android/release`

#### Repository Configuration
- ✅ Disabled staging/dev repositories in [build.gradle:38-55](SDK/ahi-sdk-multiscan-android-25.2-dev/ahi-sdk-multiscan-android-25.2-dev/build.gradle#L38-L55)
  - Reason: DataPulseTest1 user only has access to release repository
  - Error was: `AccessDenied` for `s3://ahi-prod-sdk-builds/android/staging`
- ✅ Kept only release repository: `s3://ahi-prod-sdk-builds/android/release`

#### Dependency Version Fix
- ✅ Fixed dependency version in [ahi-sdk-multiscan-android/build.gradle:94](SDK/ahi-sdk-multiscan-android-25.2-dev/ahi-sdk-multiscan-android-25.2-dev/ahi-sdk-multiscan-android/build.gradle#L94)
  - Changed from: `com.advancedhumanimaging.sdk:ahi-sdk-common:$getBranchVersion.+` (resolved to `null.null.+`)
  - Changed to: `com.advancedhumanimaging.sdk:ahi-sdk-common:23.11.+`
  - Reason: Git branch `master` doesn't contain version number, causing null version
  - Available versions in S3: `23.11.939, 23.11.900, 23.11.895, 23.10.876, 23.9.869`

#### Android SDK Configuration
- ✅ Created [local.properties](SDK/ahi-sdk-multiscan-android-25.2-dev/ahi-sdk-multiscan-android-25.2-dev/local.properties) with Android SDK path
  - `sdk.dir=/home/calvin/Android/Sdk`

### 3. Build Progress
- ✅ Gradle configuration successful
- ✅ Dependencies downloaded successfully from S3
- ✅ SDK library compilation started (39 tasks executed)
- ❌ Kotlin compilation failed with unresolved references

---

## Critical Blocker ❌

### SDK Version Incompatibility

**Error**: Compilation errors in `:ahi-sdk-multiscan-android:compileDebugKotlin`

#### Missing Classes/References:
```
SDK/ahi-sdk-multiscan-android-25.2-dev/.../AHIKeys.kt:
- Unresolved reference: key (from ahi-sdk-common)
- Unresolved reference: AHIKeyToolHelper
- Unresolved reference: AHIKeyType

SDK/ahi-sdk-multiscan-android-25.2-dev/.../RemoteAssets.kt:
- Unresolved reference: SDK_VERSION_CODE
```

#### Root Cause:
The SDK source code you have is version **25.2-dev** (development version from 2025), but your DataPulseTest1 credentials only have access to the **release repository** which contains older versions:
- Latest available: `ahi-sdk-common:23.11.939`
- SDK source requires: `ahi-sdk-common:25.2.x` (not available in release repo)

#### Why This Happens:
1. **Version 25.2-dev** is a development/unreleased version
2. Development versions depend on **staging** or **dev** S3 repositories
3. Your credentials only have access to the **release** repository
4. Release repository only has stable versions up to **23.11.x**
5. The SDK source code (v25.2) uses APIs that don't exist in v23.11 dependencies

---

## Technical Details

### Build Attempts Summary

| Attempt | Configuration | Result | Issue |
|---------|--------------|--------|-------|
| 1 | Original config with staging/dev repos | ❌ Failed | AWS credentials empty for dev repos |
| 2 | Same credentials for all repos | ❌ Failed | AccessDenied to staging/dev repos |
| 3 | Release repo only, null version | ❌ Failed | `ahi-sdk-common:null.null.+` not found |
| 4 | Release repo only, fixed version 23.11.+ | ❌ Failed | Version mismatch - missing classes |

### AWS S3 Access Summary

✅ **Has Access**:
- `s3://ahi-prod-sdk-builds/android/release`
- Available versions: 23.11.939, 23.11.900, 23.11.895, 23.10.876, 23.9.869

❌ **No Access**:
- `s3://ahi-prod-sdk-builds/android/staging` (newer/unstable versions)
- `s3://ahi-dev-sdk-builds/android` (internal development versions)

---

## Solutions & Recommendations

### Option 1: Use Pre-compiled SDK (Recommended)
Instead of building from source, use the pre-compiled SDK from Maven:

**For Flutter App** (main project):
- Already configured to use `tech.ahi.sdk:ahi-multiscan:2.2.0`
- This is the stable release version compatible with your credentials
- **Recommendation**: Continue with the Flutter app build (go back to [ahi_bodyscan_flutter](../../ahi_bodyscan_flutter/))

### Option 2: Request Dev Repository Access
Contact AHI support to upgrade your DataPulseTest1 account:
- Request access to: `s3://ahi-prod-sdk-builds/android/staging`
- This would allow downloading `ahi-sdk-common:25.2.x` dependencies
- Required for building SDK v25.2-dev from source

### Option 3: Use Older SDK Source Code
If you need to build from source for testing:
- Look for SDK source matching version `23.11.x` instead of `25.2-dev`
- Check: `SDK/ahi-app-examples-23.11-trunk/` (if available)
- This would be compatible with available dependencies

### Option 4: Contact AHI for Pre-built AAR
Request pre-compiled SDK files from AHI:
- `ahi-multiscan-25.2.x.aar` (the SDK library)
- `ahi-sdk-common-25.2.x.aar` (dependencies)
- Place in `app/libs/` and configure as local AAR

---

## Modified Files

All changes made to SDK example project:

1. **[app/src/main/java/.../MainActivity.kt:26-27](SDK/ahi-sdk-multiscan-android-25.2-dev/ahi-sdk-multiscan-android-25.2-dev/app/src/main/java/com/advancedhumanimaging/sdk/multiscan/example/MainActivity.kt#L26-L27)**
   - Updated `AHI_TOKEN` with your DataPulseTest1 JWT token
   - Added comment with VID, AID, expiration date

2. **[build.gradle:38-55](SDK/ahi-sdk-multiscan-android-25.2-dev/ahi-sdk-multiscan-android-25.2-dev/build.gradle#L38-L55)**
   - Commented out staging and dev S3 repositories
   - Reason: No access with DataPulseTest1 credentials

3. **[ahi-sdk-multiscan-android/build.gradle:92-94](SDK/ahi-sdk-multiscan-android-25.2-dev/ahi-sdk-multiscan-android-25.2-dev/ahi-sdk-multiscan-android/build.gradle#L92-L94)**
   - Changed dependency version from `$getBranchVersion.+` to `23.11.+`
   - Reason: Branch name doesn't contain version number

4. **[local.properties](SDK/ahi-sdk-multiscan-android-25.2-dev/ahi-sdk-multiscan-android-25.2-dev/local.properties)** (Created)
   - Added Android SDK location
   - `sdk.dir=/home/calvin/Android/Sdk`

---

## Recommended Next Steps

### Immediate Action: Use the Flutter App Instead

The main Flutter app ([ahi_bodyscan_flutter](../../ahi_bodyscan_flutter/)) is **the correct approach** for your use case:

1. **Why**: It uses the pre-compiled stable SDK (v2.2.0) from Maven
2. **Status**: All compilation errors already fixed (14 errors resolved)
3. **Blocker**: Same AWS credentials issue, but different solution available

### For Flutter App: Two Paths Forward

**Path A**: Get valid AWS credentials
- Contact AHI support to verify/renew your S3 credentials
- Current credentials (`[REDACTED]`) may be expired or invalid for Maven access

**Path B**: Use locally built SDK (if you can get it compiled elsewhere)
- If you have access to a working build from another developer
- Copy the compiled AAR files to your Flutter project
- Configure as local dependency

---

## Summary

**SDK Example App Build**: ❌ Cannot proceed due to version mismatch between source code (v25.2-dev) and available dependencies (v23.11.x)

**Your Credentials Work**: ✅ AWS authentication successful, S3 release repository accessible

**Root Cause**: Development SDK source code requires dependencies not available in release repository

**Recommendation**: **Focus on the main Flutter app** ([ahi_bodyscan_flutter](../../ahi_bodyscan_flutter/)) which uses stable pre-compiled SDK versions. The example SDK app is for internal AHI development and requires additional repository access.

---

## Build Logs

Complete build logs saved to:
- `/tmp/sdk_build.log` - Initial attempt
- `/tmp/sdk_build2.log` - With dev credentials
- `/tmp/sdk_build3.log` - Release repo only
- `/tmp/sdk_build4.log` - With fixed version (Android SDK missing)
- `/tmp/sdk_build5.log` - Final attempt (compilation errors)

## Contact/Support

To resolve this:
1. **For SDK v25.2 source build**: Contact AHI to request staging repository access
2. **For testing with your credentials**: Use the main Flutter app with pre-compiled SDK v2.2.0
3. **For immediate testing**: Request pre-built AAR files for v25.2 from AHI support

All necessary configuration changes have been made - only waiting on compatible SDK dependencies or repository access.
