import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Carrega propriedades da keystore de release a partir de android/key.properties
val keystorePropertiesFile = rootProject.file("android/key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        FileInputStream(keystorePropertiesFile).use { load(it) }
    }
}

android {
    namespace = "com.example.bar_boss_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.bar_boss_mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Firebase Auth requer minSdk 23+
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Configuração de assinatura para release utilizando key.properties (com verificação segura)
    signingConfigs {
        val storeFilePath = keystoreProperties.getProperty("storeFile")
        val storePasswordProp = keystoreProperties.getProperty("storePassword")
        val keyAliasProp = keystoreProperties.getProperty("keyAlias")
        val keyPasswordProp = keystoreProperties.getProperty("keyPassword")

        val hasReleaseKeystoreProps =
            !storeFilePath.isNullOrBlank() &&
            !storePasswordProp.isNullOrBlank() &&
            !keyAliasProp.isNullOrBlank() &&
            !keyPasswordProp.isNullOrBlank() &&
            file(storeFilePath!!).exists()

        if (hasReleaseKeystoreProps) {
            create("release") {
                storeFile = file(storeFilePath!!)
                storePassword = storePasswordProp
                keyAlias = keyAliasProp
                keyPassword = keyPasswordProp
            }
        }
    }

    buildTypes {
        release {
            // Mantém sem minificação e sem shrink de recursos
            isMinifyEnabled = false
            isShrinkResources = false
            // Usa a assinatura de release quando disponível; caso contrário, usa debug para não falhar o build
            val releaseConfig = signingConfigs.findByName("release")
            signingConfig = releaseConfig ?: signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase BOM para garantir compatibilidade de versões
    implementation(platform("com.google.firebase:firebase-bom:33.6.0"))

    // Firebase App Check com Play Integrity
    implementation("com.google.firebase:firebase-appcheck-playintegrity")

    // Firebase Auth (já incluído via Flutter, mas garantindo compatibilidade)
    implementation("com.google.firebase:firebase-auth")

    // Firebase Firestore (já incluído via Flutter, mas garantindo compatibilidade)
    implementation("com.google.firebase:firebase-firestore")
}