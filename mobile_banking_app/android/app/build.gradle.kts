plugins {
    id("com.android.application")
    id("kotlin-android")

    // Flutter Gradle Plugin
    id("dev.flutter.flutter-gradle-plugin")

    // Firebase Google Services
    id("com.google.gms.google-services")
}

android {
    namespace = "com.khempay.app"

    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // =====================================================
    // JAVA / DESUGARING
    // =====================================================

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11

        // Required by flutter_local_notifications
        isCoreLibraryDesugaringEnabled = true
    }

    // =====================================================
    // KOTLIN
    // =====================================================

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    // =====================================================
    // DEFAULT CONFIG
    // =====================================================

    defaultConfig {
        applicationId = "com.khempay.app"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // =====================================================
    // BUILD TYPES
    // =====================================================

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// =========================================================
// FLUTTER
// =========================================================

flutter {
    source = "../.."
}

// =========================================================
// DEPENDENCIES
// =========================================================

dependencies {
    // Required by flutter_local_notifications
    coreLibraryDesugaring(
        "com.android.tools:desugar_jdk_libs:2.1.5"
    )
}