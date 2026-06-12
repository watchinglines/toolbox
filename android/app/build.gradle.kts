plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.toolbox.scanner"
    compileSdk = 34 // or your target SDK
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

   defaultConfig {
        applicationId "com.toolbox.scanner"
        minSdk 21
        targetSdk 34
        versionCode 1
        versionName "0.1.0"
        
        // Force v2 embedding
        manifestPlaceholders = [
            'flutter_embedding_v2': 'true'
        ]
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    // 关键: 不要有 externalNativeBuild 块
    // 删除任何类似:
    //   externalNativeBuild { cmake { ... } }
    // 这些会强制使用 v1 embedding
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
    // 关键: 使用 AndroidX (v2 embedding 必需)
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.appcompat:appcompat:1.7.0")
}
