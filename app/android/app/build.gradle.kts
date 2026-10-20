import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing config lives outside the repo (android/key.properties is
// gitignored, template: android/key.properties.example). The keystore can
// never be replaced if lost: an APK signed with a different key will not
// install over the one friends already have, see docs/operations.md.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasKeystoreProperties = keystorePropertiesFile.exists()
if (hasKeystoreProperties) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

android {
    namespace = "com.github.tiltozavr2545.framebook"
    // Pinned above flutter.compileSdkVersion (35 in Flutter 3.32.8), same as
    // Amicus: current plugin releases compile against 36, and Flutter only
    // defaults to it from 3.35, which needs macOS 14+.
    compileSdk = 36
    // Pinned above flutter.ndkVersion (26.x): plugins require 27.x.
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.github.tiltozavr2545.framebook"
        minSdk = 26 // Android 8.0
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasKeystoreProperties) {
            create("release") {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Without key.properties a release build would silently be signed
            // with the debug key — an APK that cannot be updated by a real
            // release later. Fail instead (lesson from Amicus); compile checks
            // opt in explicitly with -PallowDebugSigning=true, which
            // `make build-apk-check` and CI pass.
            signingConfig = if (hasKeystoreProperties) {
                signingConfigs.getByName("release")
            } else {
                if (project.findProperty("allowDebugSigning") != "true") {
                    throw GradleException(
                        "\n" +
                            "**********************************************************************\n" +
                            "android/key.properties not found, so this RELEASE build would be\n" +
                            "signed with the DEBUG key. Friends could not update it with a real\n" +
                            "release later without uninstalling (and losing unsynced data).\n" +
                            "\n" +
                            "To compile-check on purpose, opt in:\n" +
                            "  flutter build apk --release -PallowDebugSigning=true\n" +
                            "  (or just `make build-apk-check`, which passes it)\n" +
                            "\n" +
                            "To produce a real release, create android/key.properties from\n" +
                            "android/key.properties.example (see docs/operations.md).\n" +
                            "**********************************************************************\n"
                    )
                }
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
