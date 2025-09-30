// ============================================================================
// Task: generateClasspathFile
// ============================================================================
// Purpose:
// --------
// Creates a consolidated classpath file that JDTLS (Eclipse’s Java Development
// Tools Language Server) can use to resolve dependencies in multi-module
// Gradle projects. This is especially useful when working in IDEs or editors
// that rely on JDTLS for code completion, navigation, and analysis.
//
// How it works:
// -------------
// 1. Depends on all subprojects’ `classes` tasks to ensure compilation.
// 2. Extracts the runtimeClasspath from each subproject’s "main" source set.
// 3. Flattens the results into a platform-specific string (colon `:` on Unix,
//    semicolon `;` on Windows).
// 4. Writes the string into `$buildDir/jdtls_classpath`.
//
// Why this matters:
// -----------------
// Without this file, JDTLS (and similar tools) would need to invoke Gradle
// directly to discover classpaths, which can be slow. By precomputing the
// classpath, developer tools can load projects faster.
// ============================================================================
tasks.register("generateClasspathFile") {
    // Ensure all subprojects have compiled sources before generating classpath
    dependsOn(subprojects.map { it.tasks.matching { it.name == "classes" } })

    doLast {
        // Collect runtime classpath entries from all subprojects
        val classpath = subprojects
            .flatMap { it.the<SourceSetContainer>()["main"].runtimeClasspath.files }
            .map { it.absolutePath }
            .joinToString(System.getProperty("path.separator"))

        // Define output file location
        val classpathFile = file("$buildDir/jdtls_classpath")

        // Write flattened classpath string to disk
        classpathFile.writeText(classpath)

        println("Classpath file generated at: $classpathFile")
    }
}

// ============================================================================
// Additional Logging for Task
// ============================================================================
// This extra configuration ensures developers receive clear confirmation of
// the output file’s absolute path once the task completes. This avoids guesswork
// when configuring external tools like JDTLS.
// ============================================================================
tasks.named("generateClasspathFile").configure {
    doLast {
        println(
            "Classpath for JDTLS created at: " +
            file("$buildDir/jdtls_classpath").absolutePath
        )
    }
}

// ============================================================================
// Java Toolchain Configuration for All Subprojects
// ============================================================================
// Purpose:
// --------
// Ensures that *all* subprojects in the build use the same Java version,
// regardless of whether they apply the `java` or `java-library` plugin.
// The version is sourced from the centralized version catalog
// (`rumpusLibs.versions.toml`) to avoid hardcoding values.
//
// Benefits:
// ---------
// - Guarantees consistency across modules (no "works on my machine" surprises).
// - Works with Gradle’s toolchain mechanism, so developers don’t need to
//   manually manage JDK installations.
// - Ensures compatibility across CI/CD pipelines and local builds.
//
// Notes:
// ------
// - Applies only to projects that apply `org.gradle.api.plugins.JavaPlugin`.
// - `rumpusLibs.versions.java.get()` should resolve to a string (e.g., "17").
// ============================================================================
subprojects {
    plugins.withType<org.gradle.api.plugins.JavaPlugin> {
        extensions.configure<org.gradle.api.plugins.JavaPluginExtension> {
            toolchain {
                // Apply consistent Java version from version catalog
                languageVersion.set(
                    JavaLanguageVersion.of(rumpusLibs.versions.java.get())
                )
            }
        }
    }
}
