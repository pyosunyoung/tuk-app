pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.0.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
    // FCM — google-services.json 을 읽어 Firebase 설정을 앱에 심는다
    id("com.google.gms.google-services") version "4.4.2" apply false
    // 오류 수집 — 릴리스 빌드의 난독화 매핑 파일을 올려 스택 트레이스를 읽을 수 있게 한다
    id("com.google.firebase.crashlytics") version "3.0.6" apply false
}

include(":app")
