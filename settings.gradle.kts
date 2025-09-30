import java.io.File

/*
 * --------------------------------------------------------------------------
 * Environment Variable Loader (inline implementation)
 * --------------------------------------------------------------------------
 * Purpose:
 *   - Loads `.env` files at settings evaluation time to make environment
 *     variables available for conditional project inclusion and configuration.
 *
 * Behavior:
 *   - Searches for `.env` in `rootDir`, falls back to `rootDir.parentFile`.
 *   - Parses lines in `KEY=VALUE` format.
 *   - Skips empty lines, comments (#...), and malformed entries.
 *   - Strips surrounding quotes (single/double) from values.
 *   - Exposes properties through `settings.extensions.extraProperties`.
 *
 * Why inline?
 *   - Ensures compatibility with the Kotlin DSL, since `apply(from = "...")`
 *     cannot expose top-level functions in the same way Groovy scripts can.
 */
val rootDir = settings.rootDir
val parentDir = rootDir.parentFile

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

/*
 * --------------------------------------------------------------------------
 * Determine Current Environment
 * --------------------------------------------------------------------------
 * ENV:
 *   - Controls conditional inclusion of projects and environment-specific
 *     dependency resolution.
 *   - Defaults to "DEV" if not set in `.env`.
 *
 * HEAP:
 *   - Example of an additional environment property.
 *   - Defaults to "LIMITED_HEAP" if not set.
 */
val env: String =
    if (settings.extensions.extraProperties.has("ENV")) {
        settings.extensions.extraProperties["ENV"] as String
    } else {
        "DEV"
    }

println("settings.gradle.kts: Using environment = $env")

val heap: String =
    if (settings.extensions.extraProperties.has("HEAP")) {
        settings.extensions.extraProperties["HEAP"] as String
    } else {
        "LIMITED_HEAP"
    }

println("settings.gradle.kts: Using heap configuration = $heap")

/*
 * --------------------------------------------------------------------------
 * Core Project Inclusion
 * --------------------------------------------------------------------------
 * These projects are always included, regardless of environment.
 * Gradle automatically resolves `:projectName` to a folder of the same name.
 */
include(":rumpus")
include(":admin")

/*
 * --------------------------------------------------------------------------
 * Conditional Project Inclusion (DEV or Publishing)
 * --------------------------------------------------------------------------
 * In DEV:
 *   - Includes the local `:common` project to provide IDE navigation,
 *     live reload, and local development support.
 *
 * In BETA/LIVE:
 *   - Excludes `:common` by default so the published Maven artifact is used
 *     instead of the local source.
 *
 * Exception (Publishing):
 *   - If the current Gradle invocation includes any `publish*` tasks,
 *     `:common` must be included so it can be built and published.
 *   - This ensures `publish-common.sh` and direct `./gradlew publish…`
 *     commands work regardless of environment (DEV, BETA, or LIVE).
 *
 * Implementation Details:
 *   - `gradle.startParameter.taskNames` contains the names of tasks passed
 *     to the Gradle invocation (e.g., `publishToMavenLocal`).
 *   - We check whether any of those task names contain the substring
 *     "publish" (case-insensitive) to decide whether publishing is active.
 *   - Explicitly sets `projectDir` for clarity, though not strictly required
 *     if directory name matches project name.
 */
val isPublishing: Boolean = gradle.startParameter.taskNames.any { task ->
    task.contains("publish", ignoreCase = true)
}

if (env == "DEV" || isPublishing) {
    include(":common")
    project(":common").projectDir = File(rootDir, "common")
}

/*
 * --------------------------------------------------------------------------
 * Dependency Resolution Management
 * --------------------------------------------------------------------------
 * Purpose:
 *   - Centralizes dependency version control across all subprojects.
 *   - Uses Gradle version catalogs for consistency and maintainability.
 *
 * Benefits:
 *   1. Single source of truth for dependency versions (`gradle/libs.versions.toml`).
 *   2. Type-safe access to dependencies via `libs.<alias>` in subprojects.
 *   3. IDE assistance for version updates and dependency discovery.
 *
 * Example usage in subproject build.gradle.kts:
 *     dependencies {
 *         implementation(libs.common)
 *     }
 */
dependencyResolutionManagement {
    versionCatalogs {
        val catalogName = "rumpusLibs"
        if (!this.names.contains(catalogName)) {
            create(catalogName) {
                val catalogFile = file("gradle/rumpus.versions.toml")
                println("Loading version catalog from $catalogFile")
                from(files(catalogFile))
            }
        } else {
            println("DEBUG: Version catalog '$catalogName' already exists")
        }
    }
}

/*
 * --------------------------------------------------------------------------
 * Lifecycle Debug Hooks
 * --------------------------------------------------------------------------
 * Useful for debugging dependency resolution and ensuring version catalogs
 * are loaded as expected.
 */
gradle.settingsEvaluated {
    println("DEBUG: Settings evaluated, version catalogs currently: ${dependencyResolutionManagement.versionCatalogs.names}")
}

/*
 * --------------------------------------------------------------------------
 * Additional Notes
 * --------------------------------------------------------------------------
 * - All environment variables loaded here are accessible via
 *   `settings.extensions.extraProperties`.
 * - Subprojects can read them via `rootProject.extra`.
 * - Add new environment keys to `.env` as needed; they will automatically
 *   be exposed here at configuration time.
 */
