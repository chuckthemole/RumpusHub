// Root build.gradle.kts

// Task to generate JDTLS classpath
tasks.register("generateClasspathFile") {
    dependsOn(subprojects.map { it.tasks.matching { it.name == "classes" } })

    doLast {
        val classpath = subprojects
            .flatMap { it.the<SourceSetContainer>()["main"].runtimeClasspath.files }
            .map { it.absolutePath }
            .joinToString(System.getProperty("path.separator"))

        val classpathFile = file("$buildDir/jdtls_classpath")
        classpathFile.writeText(classpath)
        println("Classpath file generated at: $classpathFile")
    }
}

// Optional: run after task
tasks.named("generateClasspathFile").configure {
    doLast {
        println("Classpath for JDTLS created at: ${file("$buildDir/jdtls_classpath").absolutePath}")
    }
}
