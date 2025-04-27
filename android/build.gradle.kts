// Top-level build file where you can add configuration options common to all sub-projects/modules

// Buildscript block to define repositories and dependencies for the Gradle build system
buildscript {
    repositories {
        google() // Google's Maven repository for Android-related dependencies
        mavenCentral() // Maven Central for other general dependencies
    }
    dependencies {
        // Android Gradle Plugin, ensure to use a compatible version based on your project's needs
        classpath("com.android.tools.build:gradle:7.0.4") // You can update this to a newer version if necessary
    }
}

// Setting a custom build directory outside the default directory structure
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir) // Set the build directory to the new location

// Configuration for all subprojects (including the main app)
subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name) // Custom build directory for each subproject
    project.layout.buildDirectory.value(newSubprojectBuildDir) // Assign the new build directory to each subproject
    project.evaluationDependsOn(":app") // Ensure that the app module is evaluated first
}

// Define a custom clean task to delete the build directory (can be used to clean the project)
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory) // Clean up the custom build directory when invoked
}

// This block ensures that all projects/modules use the repositories and dependencies defined above
allprojects {
    repositories {
        google() // Ensures all projects use the Google repository
        mavenCentral() // Ensures all projects use Maven Central repository
    }
}

// If you want to add any other global configurations or tasks, you can add them here.
