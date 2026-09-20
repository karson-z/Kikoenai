import java.util.Properties
import java.io.FileInputStream
plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
android {
    namespace = "com.karson.kikoenai"
    compileSdk = flutter.compileSdkVersion
    // 使用插件要求的最高 NDK 版本（jni 要求 28.2，其余插件 27.x），NDK 向后兼容，
    // 消除构建时的 NDK 版本警告。
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.karson.kikoenai"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    signingConfigs {
        create("release") {
            // 使用 toString() 并提供空保护，或者使用 ?.let
            keyAlias = keystoreProperties["keyAlias"]?.toString() ?: ""
            keyPassword = keystoreProperties["keyPassword"]?.toString() ?: ""
            storeFile = keystoreProperties["storeFile"]?.toString()?.let { file(it) }
            storePassword = keystoreProperties["storePassword"]?.toString() ?: ""
        }
    }
    buildTypes {
        release {
            // 有 key.properties 时用正式签名；缺失（如本地验证构建）时回退 debug
            // 签名，避免 storeFile 为空直接构建失败。注意：切换签名后覆盖安装会因
            // 签名不一致失败，需先卸载旧包。
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
        // Flutter 插件创建的 profile 类型默认 initWith(debug)，会带上
        // android:debuggable="true"。可调试应用会被 ColorOS 等 ROM 豁免后台
        // 冻结/查杀，使 profile 包无法复现 release 的后台行为。显式关闭后，
        // profile 与 release 的差异只剩 R8 混淆，是可靠的后台行为测试载体。
        getByName("profile") {
            isDebuggable = false
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
