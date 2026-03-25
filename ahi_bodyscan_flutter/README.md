# AHI BodyScan Flutter

A production-ready Flutter application for body composition analysis and health assessments using the AHI SDK and Vastmindz rPPG technology.

## Overview

This application provides:
- **Body Scanning**: Accurate body measurements and composition analysis using smartphone camera
- **Face Scanning**: Vital signs monitoring (heart rate, blood pressure, SpO2) using rPPG technology
- **Health Profiles**: Multi-profile support with comprehensive health data tracking
- **Health Assessments**: BHA (Biological Health Assessment) integration
- **Results Management**: View and track scan history and measurements

## Table of Contents

- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Configuration](#configuration)
- [Building for Production](#building-for-production)
- [Architecture](#architecture)
- [Key Features](#key-features)
- [Troubleshooting](#troubleshooting)

## Prerequisites

- **Flutter SDK**: 3.5.0 or higher
- **Dart SDK**: 3.5.0 or higher
- **Android Studio**: Arctic Fox or higher (for Android development)
- **Android SDK**:
  - Minimum SDK: 26
  - Target SDK: 36
  - Compile SDK: 36
- **NDK**: 27.0.12077973
- **AHI SDK License**: Required for body scanning functionality
- **Vastmindz SDK License**: Required for face scanning functionality

## Getting Started

### 1. Clone the Repository

```bash
git clone <repository-url>
cd ahi_bodyscan_flutter
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Environment Variables

Copy the example environment file:

```bash
cp .env.example .env
```

Edit `.env` and add your credentials:

```properties
# AHI SDK Token (required for body scans)
AHI_SDK_TOKEN=your-ahi-sdk-token-here

# Vastmindz SDK Configuration (required for face scans)
VASTMINDZ_WEBSOCKET_URL=wss://vm-production.xyz/vp/bgr_signal_socket
VASTMINDZ_AUTH_TOKEN=your-vastmindz-token-here

# Environment
ENVIRONMENT=development
```

**Important**: Never commit `.env` files to version control. The `.env` file is already added to `.gitignore`.

### 4. Configure Android Release Signing (Optional for Development)

For production builds, create `android/key.properties`:

```bash
cp android/key.properties.example android/key.properties
```

Edit `android/key.properties` with your keystore details:

```properties
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=your-key-alias
storeFile=/path/to/your/keystore.jks
```

To generate a keystore:

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### 5. Run the Application

```bash
flutter run
```

## Configuration

### Environment-Based Configuration

The app uses `flutter_dotenv` for environment-based configuration. All sensitive credentials and environment-specific settings are managed through `.env` files.

#### Configuration Files

- **`.env`**: Active environment variables (gitignored)
- **`.env.example`**: Template showing required variables
- **`lib/core/config/app_config.dart`**: Configuration service that loads and provides access to environment variables

#### Accessing Configuration

```dart
import 'package:ahi_bodyscan_flutter/core/config/app_config.dart';

// Get AHI SDK token
final token = AppConfig.ahiSDKToken;

// Get Vastmindz WebSocket URL
final wsUrl = AppConfig.vastmindzWebSocketURL;

// Get environment
final env = AppConfig.environment; // 'development', 'staging', or 'production'
```

### Package Configuration

- **Package Name**: `tech.ahi.bodyscan`
- **App Name**: AHI BodyScan
- **Bundle ID**: tech.ahi.bodyscan (Android)

## Building for Production

See [DEPLOYMENT.md](DEPLOYMENT.md) for a comprehensive production deployment checklist.

Quick build commands:

```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release
```

## Architecture

### Project Structure

```
lib/
├── core/                           # Core application modules
│   ├── config/                     # Configuration (AppConfig)
│   ├── router/                     # Navigation (GoRouter)
│   ├── services/                   # Core services (AHI SDK, Demo)
│   └── theme/                      # App theming
├── features/                       # Feature modules
│   ├── auth/                       # Authentication
│   ├── home/                       # Home dashboard
│   ├── profile/                    # User profiles
│   ├── reports/                    # Scan results and history
│   └── settings/                   # App settings
├── services/                       # Additional services
│   ├── profile_service.dart        # Profile management
│   └── vastmindz_sdk_service.dart  # Face scan SDK
├── shared/                         # Shared widgets and utilities
│   └── widgets/                    # Reusable UI components
└── src/                            # AHI Turnkey SDK integration
    ├── ahi_turnkey_launchers/      # SDK launchers
    ├── ahi_turnkey_models/         # Data models
    ├── ahi_turnkey_services/       # SDK services
    └── ahi_turnkey_widgets/        # SDK UI components
```

### State Management

The app uses **Provider** pattern for state management:
- `ProfileProvider`: Manages user profiles and selection
- Service classes use singleton pattern where appropriate

### SDK Integration

#### AHI SDK (Body Scans)
- **Purpose**: Body measurements and composition analysis
- **Integration**: Turnkey SDK (`lib/src/ahi_turnkey_*`)
- **Configuration**: Initialized in `lib/core/services/ahi_sdk_service.dart`
- **Token**: Loaded from `AppConfig.ahiSDKToken`

#### Vastmindz SDK (Face Scans)
- **Purpose**: Vital signs monitoring via rPPG
- **Integration**: Custom WebSocket service
- **Configuration**: `lib/services/vastmindz_sdk_service.dart`
- **Credentials**: Loaded from `AppConfig` (WebSocket URL and auth token)

### Profile Health Data Integration

The app integrates user profile health data with SDK scans:

- **Profile Fields**: smoking status, hypertension, diabetes status
- **SDK Integration**: Automatically passed to AHI SDK during body scans
- **Conversion**: Profile health data is converted to SDK-expected format in `tk_body_scan_launcher.dart:95-143`

Example conversion:
```dart
// Smoking: 'current' → true, 'former'/'never' → false
isSmoker = selectedProfile.smokingStatus.toLowerCase() == 'current';

// Hypertension: 'yes' → true, 'no' → false
hasHypertension = selectedProfile.hasHypertension.toLowerCase() == 'yes';

// Diabetes: 'type_1', 'type_2', 'prediabetic', 'non_diabetic'
```

## Key Features

### Multi-Profile Support
- Create and manage multiple user profiles
- Each profile tracks: demographics, health conditions, scan history
- Profile selection persists across app sessions

### Body Scanning
- Camera-based body measurement capture
- Measurements: chest, waist, hips, thigh, inseam
- Body composition: body fat %, muscle mass, fat mass
- Health ratios: waist-to-height, waist-to-hip

### Face Scanning (rPPG)
- Non-invasive vital signs monitoring
- Metrics: heart rate, blood pressure, SpO2, stress level
- Real-time signal quality feedback

### Health Assessment (BHA)
- Comprehensive health profile generation
- Based on body scan results + health survey
- Personalized recommendations

### Demo Account
Production builds include demo login functionality:
- Username: `demo@ahi.tech` / Password: `demo123`
- Username: `test@ahi.tech` / Password: `test123`

## Troubleshooting

### Build Issues

**Issue**: "AHI_SDK_TOKEN is not set"
- **Solution**: Ensure `.env` file exists and contains valid `AHI_SDK_TOKEN`

**Issue**: Gradle build fails with signing errors
- **Solution**: For development, `key.properties` is optional (debug signing is used). For production, ensure `key.properties` is properly configured.

**Issue**: Native library conflicts (OpenCV)
- **Solution**: The build is configured to handle OpenCV conflicts between AHI SDK (4.5.5) and Vastmindz SDK (4.1.2). See `android/app/build.gradle.kts:69-105`

### Runtime Issues

**Issue**: SDK initialization fails
- **Solution**: Check that both `AHI_SDK_TOKEN` and `VASTMINDZ_AUTH_TOKEN` are valid and not expired

**Issue**: Content appears behind bottom navigation bar
- **Solution**: This has been fixed in `main_navigation_shell.dart:39` by setting `SafeArea(bottom: false)`

**Issue**: Profile health data not used in scans
- **Solution**: This has been fixed. The SDK now receives actual profile health data (smoking, hypertension, diabetes) from `tk_body_scan_launcher.dart`

### Getting Help

For additional documentation, see:
- [AHI SDK Setup Guide](AHI_SDK_SETUP_GUIDE.md)
- [Deployment Checklist](DEPLOYMENT.md)
- [Quick Start Testing](QUICK_START_TESTING.md)

## License

Copyright (c) AHI. All rights reserved.

## Contact

For support or questions about the AHI SDK, contact AHI support.
