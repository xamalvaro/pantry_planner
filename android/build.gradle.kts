allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Define Kotlin version as a top-level property
val kotlinVersion by extra("1.8.10")
// Define Java version to use consistently
val javaVersion by extra(JavaVersion.VERSION_1_8)

plugins {
    // Add the dependency for the Google services Gradle plugin
    id("com.google.gms.google-services") version "4.3.15" apply false
}

// Apply consistent settings to all projects
allprojects {
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        kotlinOptions {
            jvmTarget = "1.8" // Set JVM target to 1.8 to match Java
            apiVersion = "1.8"
            languageVersion = "1.8"
            freeCompilerArgs = listOf(
                "-Xskip-metadata-version-check",
                "-Xuse-ir"
            )
        }
    }

    // Apply to Java compilation as well
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = javaVersion.toString()
        targetCompatibility = javaVersion.toString()
    }

    configurations.all {
        resolutionStrategy {
            // Force consistent Kotlin runtime version across all dependencies
            force("org.jetbrains.kotlin:kotlin-stdlib:$kotlinVersion")
            force("org.jetbrains.kotlin:kotlin-stdlib-common:$kotlinVersion")
            force("org.jetbrains.kotlin:kotlin-stdlib-jdk7:$kotlinVersion")
            force("org.jetbrains.kotlin:kotlin-stdlib-jdk8:$kotlinVersion")
            force("org.jetbrains.kotlin:kotlin-reflect:$kotlinVersion")
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}