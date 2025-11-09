allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Prevent cross-drive build directory conflicts for Flutter plugins
// Flutter plugins from pub cache (C:) must use their own build directories,
// not the project's build directory (D:)
subprojects {
    val projectPath = project.projectDir.absolutePath.replace("\\", "/")
    val rootPath = rootProject.projectDir.absolutePath.replace("\\", "/")
    
    // Check if this is a Flutter plugin from pub cache (different drive)
    val isFlutterPlugin = (projectPath.contains("/Pub/Cache/") || 
                          projectPath.contains("/pub.flutter-io.cn/") ||
                          projectPath.contains("\\Pub\\Cache\\") ||
                          projectPath.contains("\\pub.flutter-io.cn\\")) &&
                          !projectPath.startsWith(rootPath)
    
    if (isFlutterPlugin) {
        // Force Flutter plugins to use their own build directory
        // This prevents cross-drive path conflicts
        val pluginBuildDir = project.projectDir.resolve("build")
        project.layout.buildDirectory.set(pluginBuildDir)
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
