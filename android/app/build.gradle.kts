plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.hariyali"
    compileSdk = 34
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.hariyali"

        // ── Minimum SDK 21 required for:
        //    - Firebase (minSdk 19, but 21 recommended)
        //    - speech_to_text plugin
        //    - flutter_tts plugin
        //    - permission_handler plugin
        minSdk = 21

        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Required for multidex — Firebase + multiple plugins
        // can exceed the 64K method limit on older Android
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // TODO: Replace with your own signing config before publishing
            // to Google Play. Using debug keys for now so flutter run --release works.
            signingConfig = signingConfigs.getByName("debug")

            // Shrink and optimize the release APK
            isMinifyEnabled = false
            isShrinkResources = false
        }
        debug {
            isDebuggable = true
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Multidex support for Android < 5.0 (API < 21 fallback)
    implementation("androidx.multidex:multidex:2.0.1")
}