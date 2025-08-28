plugins {
    id("com.android.application")
    id("kotlin-android")                 // keep as-is; version is set in the root
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.flutter_application_1"

    compileSdk = flutter.compileSdkVersion.toInt()
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.flutter_application_1"
        // minSdk must be >= 21 for desugaring
        minSdk = maxOf(21, flutter.minSdkVersion.toInt())
        targetSdk = flutter.targetSdkVersion.toInt()

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // ✅ Java 17 + core library desugaring
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ Needed when isCoreLibraryDesugaringEnabled = true
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.2")
}
