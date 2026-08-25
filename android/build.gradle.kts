allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// 部分第三方 Flutter 插件（如 disk_space_2）在自己的 build.gradle 里用了
// `kotlin { }` 扩展，但只 apply 了 `com.android.library`，未显式应用 Kotlin 插件。
// 新版 Flutter plugin loader 不会自动给插件子项目应用 Kotlin 插件，导致
// `Could not find method kotlin()` 报错。
// 这里在配置阶段给所有 Android library 子项目补上 Kotlin 插件。
subprojects {
    project.plugins.withId("com.android.library") {
        project.plugins.apply("org.jetbrains.kotlin.android")
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
