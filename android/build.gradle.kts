plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // 👇 Apply the Google services plugin here
    id("com.google.gms.google-services") version "4.4.4" apply false
    id("com.google.gms.google-services")
}

android {
    namespace = "com.hariyali.app"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.hariyali.app"
        minSdk = 21
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    // ✅ Firebase BoM (Bill of Materials)
    implementation(platform("com.google.firebase:firebase-bom:34.7.0"))

    // ✅ Firebase Analytics (example)
    implementation("com.google.firebase:firebase-analytics")

    // 🔁 Add other Firebase products you need:
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-database")
    implementation("com.google.firebase:firebase-storage")
    implementation("com.google.firebase:firebase-messaging")
}