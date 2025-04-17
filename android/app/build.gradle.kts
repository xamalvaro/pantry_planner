plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Access versions from root project
val kotlinVersion = rootProject.extra["kotlinVersion"] as String
val javaVersion = rootProject.extra["javaVersion"] as JavaVersion

android {
    namespace = "com.tbd.pantry_pal"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = javaVersion
        targetCompatibility = javaVersion
        // Add this line for desugaring
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = javaVersion.toString()
        // Match Kotlin API version with the version expected by Firebase dependencies
        apiVersion = "1.8"
        languageVersion = "1.8"
        // Fix for "No enum constant org.jetbrains.kotlin.statistics.metrics.BooleanMetrics.JVM_COMPILER_IR_MODE"
        freeCompilerArgs = listOf("-Xskip-metadata-version-check", "-Xuse-ir")
    }

    defaultConfig {
        applicationId = "com.tbd.pantry_pal"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// Add dependencies section
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:1.2.2")

    // Add Kotlin standard library with the correct version
    implementation("org.jetbrains.kotlin:kotlin-stdlib:$kotlinVersion")
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:$kotlinVersion")

    // Import the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:33.12.0"))

    // Add Firebase products
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")

    // Add the multidex library to support minSdk < 21
    implementation("androidx.multidex:multidex:2.0.1")
}

flutter {
    source = "../.."
}