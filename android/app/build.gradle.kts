import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        FileInputStream(keystorePropertiesFile).use { load(it) }
    }
}

android {
    namespace = "br.com.bar_boss_mobile"
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
        applicationId = "br.com.bar_boss_mobile"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        val storeFilePath = keystoreProperties["storeFile"]?.toString()
        val storePasswordProp = keystoreProperties["storePassword"]?.toString()
        val keyAliasProp = keystoreProperties["keyAlias"]?.toString()
        val keyPasswordProp = keystoreProperties["keyPassword"]?.toString()

        val hasReleaseKeystoreProps =
            !storeFilePath.isNullOrBlank() &&
            !storePasswordProp.isNullOrBlank() &&
            !keyAliasProp.isNullOrBlank() &&
            !keyPasswordProp.isNullOrBlank()

        if (hasReleaseKeystoreProps) {
            create("release") {
                storeFile = file(storeFilePath!!)
                storePassword = storePasswordProp
                keyAlias = keyAliasProp
                keyPassword = keyPasswordProp
            }
        } else {
            println("⚠️  Keystore de release não configurada ou arquivo ausente.")
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            val releaseConfig = signingConfigs.findByName("release")
            check(releaseConfig != null) {
                "Release signing is not configured. Create android/key.properties and a release keystore."
            }
            signingConfig = releaseConfig
        }

        debug {
            signingConfig = signingConfigs.findByName("debug")
        }
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.6.0"))
    implementation("com.google.firebase:firebase-appcheck-playintegrity")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
}