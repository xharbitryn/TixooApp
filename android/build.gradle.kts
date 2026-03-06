// Top-level build file for the entire Flutter Android project
// File: android/build.gradle.kts

buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        // ✅ Required for Firebase services (Auth, Firestore, etc.)
        classpath("com.google.gms:google-services:4.4.0")

        // (Optional) Firebase Crashlytics and Performance Monitoring
        // classpath("com.google.firebase:firebase-crashlytics-gradle:2.9.9")
        // classpath("com.google.firebase:perf-plugin:1.4.2")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ✅ Configure custom build directory for Flutter
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    project.evaluationDependsOn(":app")
}

// ✅ Register clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
