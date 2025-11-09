pluginManagement {
    val flutterSdkPath = run {
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
    id("com.android.application") version "8.7.3" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")

// Prevent cross-drive build directory conflicts for Flutter plugins
// Flutter plugins from pub cache (C:) should use their own build directories,
// not the project's build directory (D:)
gradle.beforeProject {
    val projectPath = project.projectDir.absolutePath.replace("\\", "/")
    val rootPath = rootProject.projectDir.absolutePath.replace("\\", "/")
    
    // Check if this is a Flutter plugin from pub cache (different drive)
    val isFlutterPlugin = (projectPath.contains("/Pub/Cache/") || 
                          projectPath.contains("/pub.flutter-io.cn/") ||
                          projectPath.contains("\\Pub\\Cache\\") ||
                          projectPath.contains("\\pub.flutter-io.cn\\")) &&
                          !projectPath.startsWith(rootPath)
    
    if (isFlutterPlugin) {
        // Force Flutter plugins to use their own build directory immediately
        // This must happen before Flutter plugin loader sets build directory
        val pluginBuildDir = project.projectDir.resolve("build")
        project.layout.buildDirectory.set(pluginBuildDir)
        
        // Also set it in afterEvaluate as a fallback
        project.afterEvaluate {
            val currentBuildDir = project.layout.buildDirectory.asFile.get()
            val expectedBuildDir = project.projectDir.resolve("build")
            if (currentBuildDir.absolutePath != expectedBuildDir.absolutePath) {
                project.layout.buildDirectory.set(expectedBuildDir)
            }
        }
    }
}