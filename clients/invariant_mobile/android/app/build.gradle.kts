plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.invariant.protocol.invariant_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Enable Desugaring for modern Time APIs on older Androids
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        // Target JVM 17 to match compileOptions
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.invariant.protocol.invariant_mobile"
        
        // Min SDK 21 required for flutter_local_notifications
        minSdk = flutter.minSdkVersion 
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // MultiDex required for Desugaring
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            // Shrink resources for smaller APK
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Desugaring Library
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
