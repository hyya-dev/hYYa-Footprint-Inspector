import java.util.Properties

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.compose.compiler)
}

/**
 * Play upload-signing credentials live OUTSIDE the repo, in the owner's Keys Wallet, as for the
 * sibling hYYa apps. Nothing secret is committed. Without them the release builds unsigned.
 */
val keystoreFile: File = File(
    "/Users/hyya/Library/Mobile Documents/com~apple~CloudDocs/H-iCloud Drive/*Keys Wallet/hYYa Footprint Inspector Keys/android-signing/keystore.properties",
)
val keystoreProps = Properties().apply {
    if (keystoreFile.isFile) keystoreFile.inputStream().use { load(it) }
}

android {
    namespace = "com.hyya.footprintinspector"
    compileSdk = 37

    defaultConfig {
        applicationId = "com.hyya.footprintinspector"
        minSdk = 33
        targetSdk = 36
        // versionName is the marketing version (owner: 1.0.0 on every store); versionCode is the
        // build number and may be bumped freely, but Play refuses a code it already holds.
        versionCode = 6
        versionName = "1.0.0"
    }

    signingConfigs {
        if (keystoreProps.containsKey("storeFile")) {
            create("upload") {
                storeFile = File(keystoreFile.parentFile, File(keystoreProps.getProperty("storeFile")).name)
                storePassword = keystoreProps.getProperty("storePassword")
                keyAlias = keystoreProps.getProperty("keyAlias")
                keyPassword = keystoreProps.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("upload")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
        debug { versionNameSuffix = "-debug" }
    }
    buildFeatures { compose = true; buildConfig = true }
    compileOptions { sourceCompatibility = JavaVersion.VERSION_17; targetCompatibility = JavaVersion.VERSION_17 }
    kotlin { compilerOptions { jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17) } }
    testOptions { unitTests { isReturnDefaultValues = true } }
}

dependencies {
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.lifecycle.runtime.ktx)
    implementation(libs.androidx.lifecycle.viewmodel.compose)
    implementation(libs.androidx.activity.compose)
    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.compose.ui)
    implementation(libs.androidx.compose.material3)
    implementation(libs.androidx.compose.material.icons)
    implementation(libs.androidx.work.runtime.ktx)
    testImplementation(libs.junit)
}
