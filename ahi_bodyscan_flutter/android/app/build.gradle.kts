plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

// Load keystore properties from key.properties file
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "tech.ahi.bodyscan"
    compileSdk = 36  // Updated to 36 for camera plugin compatibility
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    // Configure signing configs before referencing them in buildTypes
    signingConfigs {
        // Release signing configuration
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    defaultConfig {
        // Production application ID
        applicationId = "tech.ahi.bodyscan"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26  // Required for AHI MultiScan SDK (was 23 for Vastmindz)
        targetSdk = 36  // Updated to 36 for plugin compatibility
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Use release signing if key.properties exists, otherwise use debug for development
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                println("⚠️  WARNING: key.properties not found. Using debug signing for release build.")
                println("⚠️  For production, create key.properties from key.properties.example")
                signingConfigs.getByName("debug")
            }
            // Required for Vastmindz SDK
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    // Packaging options for multiple SDKs
    packaging {
        resources.excludes.add("META-INF/*")
        resources.excludes.add("META-INF/DEPENDENCIES")
        resources.excludes.add("META-INF/LICENSE")
        resources.excludes.add("META-INF/LICENSE.txt")
        resources.excludes.add("META-INF/NOTICE")
        resources.excludes.add("META-INF/NOTICE.txt")

        // Handle duplicate native libraries from different SDKs
        // AHI body scan requires OpenCV 4.5.5 (libopencv_java4.so), pulled in
        // transitively by ahi-sdk-bodyscan. We no longer bundle the Vastmindz
        // OpenCV 4.1.2 AAR, so these pickFirsts entries are defence-in-depth in
        // case any future transitive dep reintroduces a conflicting copy.
        jniLibs.pickFirsts.add("lib/arm64-v8a/libopencv_java4.so")
        jniLibs.pickFirsts.add("lib/armeabi-v7a/libopencv_java4.so")
        jniLibs.pickFirsts.add("lib/x86_64/libopencv_java4.so")
        jniLibs.pickFirsts.add("lib/x86/libopencv_java4.so")

        // C++ shared library conflicts
        jniLibs.pickFirsts.add("lib/arm64-v8a/libc++_shared.so")
        jniLibs.pickFirsts.add("lib/armeabi-v7a/libc++_shared.so")
        jniLibs.pickFirsts.add("lib/x86_64/libc++_shared.so")
        jniLibs.pickFirsts.add("lib/x86/libc++_shared.so")

        // Vastmindz face-scan native libs are excluded from the APK. They embed
        // OpenCV 4.1.2 header-inlined code paths (cv::Mat::create, etc.) that
        // conflict at runtime with AHI body scan's OpenCV 4.5.5 and SIGSEGV inside
        // libcontourGenerator.so. Face scan invocations will fail with
        // UnsatisfiedLinkError while these excludes are in place.
        jniLibs.excludes.add("lib/*/librppg_core.so")
        jniLibs.excludes.add("lib/*/librppg_bridge.so")
    }
    
    buildFeatures {
        buildConfig = true
    }

    // Resolution strategy commented out - now using OpenCV 4.5.5 from AHI SDK
    // configurations.all {
    //     resolutionStrategy {
    //         // Exclude any transitive OpenCV 4.1.2 dependencies
    //         exclude(group = "opencv", module = "android")
    //     }
    // }
}

flutter {
    source = "../.."
}

dependencies {
    // AHI SDK Version - using official Maven repository
    val ahiSdkVersion = "23.11.+"

    // AHI MultiScan SDK - Official Maven dependency (includes common module transitively)
    implementation("com.advancedhumanimaging.sdk:ahi-sdk-multiscan:$ahiSdkVersion")

    // AHI Body Scan SDK - Official Maven dependency
    // Note: This will use OpenCV 4.5.5 (libopencv_java4.so)
    implementation("com.advancedhumanimaging.sdk:ahi-sdk-bodyscan:$ahiSdkVersion")

    // AHI Face Scan SDK removed - using Vastmindz SDK for face scanning instead
    // (AHI FaceScan's internal Nuralogix license expired)

    // ML Kit dependencies (required by AHI SDK)
    implementation("com.google.mlkit:pose-detection:18.0.0-beta3")
    implementation("com.google.mlkit:face-detection:16.1.5")

    // CameraX dependencies (required by AHI SDK)
    implementation("androidx.camera:camera-camera2:1.3.0")
    implementation("androidx.camera:camera-lifecycle:1.3.0")
    implementation("androidx.camera:camera-view:1.3.0")

    // TensorFlow Lite (required by AHI SDK)
    implementation("org.tensorflow:tensorflow-lite:2.11.0")
    implementation("org.tensorflow:tensorflow-lite-support:0.4.3")
    implementation("org.tensorflow:tensorflow-lite-metadata:0.4.3")

    // AndroidX Core libraries
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.11.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")

    // Kotlin Coroutines (used by AHI SDK)
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3")

    // OpenCV 4.5.5 is provided transitively by ahi-sdk-bodyscan and is required by
    // libcontourGenerator.so (symbol _ZN2cv3MatC1Ev). Vastmindz's librppg_core.so is
    // statically linked against OpenCV at the C++ level and does not import any
    // org.opencv.* Java classes, so no separate OpenCV 4.1.2 dependency is needed.
}
