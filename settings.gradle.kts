import java.io.File

// --------------------------------------------------------------------------
// Load environment variables from .env (inline version)
// --------------------------------------------------------------------------
// This block replaces the external EnvLoader.kts script to ensure Kotlin DSL
// compatibility. It reads `.env` files from the project root or parent directory.
//
// Behavior:
// - Looks for `.env` in the rootDir, then falls back to rootDir.parentFile
// - Parses lines in KEY=VALUE format
// - Ignores comment lines starting with '#' and malformed lines
// - Strips surrounding quotes (single or double) from values
// - Sets each property in `settings.extensions.extraProperties` for use throughout
//   the build script (accessible in Kotlin DSL)
val rootDir = settings.rootDir
val parentDir = rootDir.parentFile

// Determine the file to read (.env in rootDir preferred)
val envFile = File(rootDir, ".env").takeIf { it.exists() } ?: File(parentDir, ".env")

if (envFile.exists()) {
    println("EnvLoader: Found .env file at ${envFile.absolutePath}")
    envFile.forEachLine { line ->
        val trimmed = line.trim()
        if (trimmed.isNotEmpty() && !trimmed.startsWith("#") && trimmed.contains("=")) {
            val (rawKey, rawValue) = trimmed.split("=", limit = 2)
            val key = rawKey.trim()
            val value = rawValue.trim().removeSurrounding("\"").removeSurrounding("'")
            println("EnvLoader: Setting settings.extraProperties property: $key = $value")
            settings.extensions.extraProperties.set(key, value)
        } else {
            println("EnvLoader: Skipping line: '$line'")
        }
    }
} else {
    println("EnvLoader: No .env file found in $rootDir or $parentDir")
}

// --------------------------------------------------------------------------
// Determine the current environment
// --------------------------------------------------------------------------
// Reads the 'ENV' property from the loaded environment variables. Defaults
// to "DEV" if not explicitly set. This controls conditional project inclusion
// and other environment-specific configuration.
val env: String =
        if (settings.extensions.extraProperties.has("ENV")) {
            settings.extensions.extraProperties["ENV"] as String
        } else {
            "DEV"
        }

println("settings.gradle.kts: Using environment = $env")

// --------------------------------------------------------------------------
// Optional additional environment variables
// --------------------------------------------------------------------------
// Example: HEAP configuration. Defaulting to LIMITED_HEAP if not set in .env
val heap: String =
        if (settings.extensions.extraProperties.has("HEAP")) {
            settings.extensions.extraProperties["HEAP"] as String
        } else {
            "LIMITED_HEAP"
        }

println("settings.gradle.kts: Using heap configuration = $heap")

// --------------------------------------------------------------------------
// Include core subprojects
// --------------------------------------------------------------------------
// These projects are always included, regardless of environment. Gradle
// automatically maps the project name to a folder of the same name in rootDir.
include(":rumpus")
include(":admin")

// --------------------------------------------------------------------------
// Include the 'common' project only in DEV environment
// --------------------------------------------------------------------------
// In DEV mode, we include the local ':common' project to ensure IDE features
// like IntelliSense, live reload, and local development work seamlessly. In
// LIVE/BETA, the published artifact is used instead, avoiding conflicts with
// Maven/Gradle dependencies.
//
// The `projectDir` explicitly maps the logical Gradle project to a physical
// folder. This is optional if the folder name matches the project name,
// but makes the configuration explicit and easier to maintain.
if (env == "DEV") {
    include(":common")
    project(":common").projectDir = File(rootDir, "common")
}

// --------------------------------------------------------------------------
// Dependency Resolution Management
// --------------------------------------------------------------------------
// This block centralizes dependency version control and version catalogs
// for all subprojects. By using a version catalog, you can:
//   1. Define dependency versions in a single place (`libs.versions.toml`),
//      making upgrades and maintenance easier.
//   2. Reference dependencies in build.gradle.kts files via `libs.<alias>`,
//      improving readability and reducing duplication.
//   3. Enable IDE support for version completion, inspection, and updates.
//
// Example usage in a subproject:
//     dependencies {
//         implementation(libs.common) // refers to version declared in libs.versions.toml
//     }
//
// Notes:
// - The file `gradle/libs.versions.toml` should live at the top level of the repo.
// - Any new dependencies or version updates should be added there first.
// - Multiple catalogs can be defined here if needed for different sets of dependencies.
// - This approach is compatible with Gradle Kotlin DSL and provides better
//   type-safe access than manually declaring string versions in each build file.
println("DEBUG: Entering dependencyResolutionManagement block")

dependencyResolutionManagement {
    versionCatalogs {
        val catalogName = "rumpusLibs"
        if (!this.names.contains(catalogName)) {
            println("DEBUG: Creating version catalog '$catalogName'")
            create(catalogName) {
                val catalogFile = file("gradle/rumpus.versions.toml")
                println("DEBUG: About to call from($catalogFile)")
                println("DEBUG: Stacktrace of from() call:")
                Thread.currentThread().stackTrace.forEach { println(it) }
                from(files(catalogFile))
            }
        } else {
            println("DEBUG: Version catalog '$catalogName' already exists")
        }
    }
}

println("DEBUG: Exiting dependencyResolutionManagement block")

// --------------------------------------------------------------------------
// Additional Notes
// --------------------------------------------------------------------------
// - This inline approach ensures full Kotlin DSL compatibility; `apply(from = ...)`
//   cannot expose top-level functions in Kotlin DSL like in Groovy.
// - All environment variables loaded here are available as `settings.extensions.extraProperties`.
// - You can access them in subprojects via `rootProject.extra` if needed.

gradle.settingsEvaluated {
    println("DEBUG: Settings evaluated, version catalogs currently: ${dependencyResolutionManagement.versionCatalogs.names}")
}