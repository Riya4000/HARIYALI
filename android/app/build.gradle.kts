plugins {
    id 'com.android.application'
    id 'com.google.gms.google-services'
    id 'kotlin-android'
}


android {
    namespace "com.example.hariyali"
    compileSdk 34

    defaultConfig {
        applicationId "com.example.hariyali"
        minSdk 24
        targetSdk 34
        versionCode 1
        versionName "1.0"
        multiDexEnabled true
    }
}

dependencies {
    implementation 'com.google.firebase:firebase-auth:22.3.0'
    implementation 'com.google.firebase:firebase-database:20.3.0'
    implementation(platform("com.google.firebase:firebase-bom:34.7.0"))
    implementation("com.google.firebase:firebase-analytics")
}