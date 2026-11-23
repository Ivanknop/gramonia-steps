import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Firma de release: la keystore y sus contraseñas se leen de
// android/key.properties, que NO va a git (ver key.properties.example).
// Sin ese archivo completo, el release falla: nunca se firma con la clave
// de debug.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use { load(it) }
    }
}
val releaseKeys = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
val releaseSigningProblem: String? = when {
    !keystorePropertiesFile.exists() ->
        "Falta android/key.properties (copiá key.properties.example y completalo)."
    releaseKeys.any { keystoreProperties.getProperty(it).isNullOrBlank() } ->
        "android/key.properties está incompleto: hacen falta ${releaseKeys.joinToString()}."
    !file(keystoreProperties.getProperty("storeFile")).exists() ->
        "No encuentro la keystore: ${keystoreProperties.getProperty("storeFile")} " +
            "(la ruta es relativa a android/app/)."
    else -> null
}

android {
    namespace = "ar.gramonia.rpg"
    compileSdk = 37 // permission_handler pide 37 o más
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "ar.gramonia.rpg"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseSigningProblem == null) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Solo con la clave de release. Si falta, el release falla
            // (ver abajo): así nunca se reparte un APK firmado con debug.
            signingConfig =
                if (releaseSigningProblem == null) signingConfigs.getByName("release") else null
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

// Cualquier tarea de release falla si la firma de release no está lista.
// Las de debug siguen andando sin key.properties.
tasks.configureEach {
    if (name.contains("Release") && releaseSigningProblem != null) {
        doFirst { throw GradleException("Firma de release: $releaseSigningProblem") }
    }
}
