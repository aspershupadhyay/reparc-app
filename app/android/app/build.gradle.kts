import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing reads android/key.properties, which is never committed.
// CI writes it from protected secrets (handbook 17.4).
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
val hasReleaseKey = keystoreProperties.getProperty("storeFile") != null

// The Google Play build (handbook 17.10): `flutter build appbundle
// --dart-define=REPARC_STORE=play`. Flutter hands the defines to Gradle as
// base64 text, so the Dart code and this file read the same one switch.
val isPlayBuild = (project.findProperty("dart-defines") as String?)
    ?.split(",")
    ?.any { runCatching { String(java.util.Base64.getDecoder().decode(it)) }.getOrNull() == "REPARC_STORE=play" }
    ?: false

android {
    namespace = "app.reparc.reparc"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // flutter_local_notifications (rest alert) needs Java 8+ APIs on older Android.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // To confirm: final application ID before the first store upload.
        applicationId = "app.reparc.reparc"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Health Connect and the health plugin need Android 8 (API 26) or later.
        minSdk = maxOf(flutter.minSdkVersion, 26)
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // MainActivity leaves out the installer channel in the Play build.
        buildConfigField("boolean", "PLAY_BUILD", isPlayBuild.toString())
    }

    buildFeatures {
        buildConfig = true
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    // `flutter build apk --split-per-abi` (the release workflow) makes one
    // APK per processor type, about 45% smaller than the full one. Keep
    // the full APK too: the website links to it, and app versions before
    // 0.4.9 download it (handbook 17.3). The Flutter plugin turns it off.
    if (project.hasProperty("split-per-abi")) {
        splits.abi.isUniversalApk = true
    }

    // The Play build drops the in-app installer and REQUEST_INSTALL_PACKAGES.
    if (isPlayBuild) {
        sourceSets.getByName("release").manifest.srcFile("src/play/AndroidManifest.xml")
    }

    buildTypes {
        release {
            // Without key.properties, a local release build uses the debug key.
            // Google Play rejects debug-signed uploads, so it cannot ship by mistake.
            signingConfig = signingConfigs.getByName(if (hasReleaseKey) "release" else "debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // FileProvider, to hand a checked update APK to Android's installer
    // (MainActivity). The same version url_launcher already brings in.
    implementation("androidx.core:core:1.17.0")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
