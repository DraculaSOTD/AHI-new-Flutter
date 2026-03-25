allprojects {
    repositories {
        google()
        mavenCentral()
        // Required for Vastmindz SDK dependencies
        maven { url = uri("https://jitpack.io") }
        maven { url = uri("https://maven.google.com") }
        // Repository for Vastmindz SDK - check if project exists first
        if (findProject(":rppg_common") != null) {
            maven {
                url = uri("${project(":rppg_common").projectDir}/build")
            }
        }
        // Additional repository for SDK dependencies
        jcenter()

        // AHI SDK Maven S3 Repository - DataPulseTest1
        // Updated to use correct production bucket (same as Turnkey app)
        maven {
            url = uri("s3://ahi-prod-sdk-builds/android/release")
            credentials(AwsCredentials::class) {
                accessKey = findProperty("ahiMavenAccessKey") as? String ?: System.getenv("AHI_MAVEN_ACCESS_KEY")
                secretKey = findProperty("ahiMavenSecretKey") as? String ?: System.getenv("AHI_MAVEN_SECRET_KEY")
            }
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
