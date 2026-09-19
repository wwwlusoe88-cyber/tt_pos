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
    plugins.withId("com.android.library") {
        val android = extensions.findByName("android") as? com.android.build.gradle.LibraryExtension
        android?.ndkVersion = "29.0.14206865"
    }
    plugins.withId("com.android.application") {
        val android = extensions.findByName("android") as? com.android.build.gradle.AppExtension
        android?.ndkVersion = "29.0.14206865"
    }
}

// AGP 8+ အောက်မှာ Namespace မပါတဲ့ Plugin များကို အလိုအလျောက် Namespace သတ်မှတ်ပေးခြင်း
subprojects {
    plugins.withId("com.android.library") {
        val android = extensions.findByName("android") as? com.android.build.gradle.LibraryExtension
        if (android != null && android.namespace == null) {
            android.namespace = "com.flutter.plugins.${project.name.replace("-", "_")}"
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
