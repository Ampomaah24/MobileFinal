pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "evently"
include(":app")

// This is needed for the Flutter project structure
setBinding(new Binding([gradle: this]))
evaluate(new File(settingsDir.parentFile, 'android/include_flutter.groovy'))