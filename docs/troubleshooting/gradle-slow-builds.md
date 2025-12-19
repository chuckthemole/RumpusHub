\# Gradle Build Is Extremely Slow — Troubleshooting Guide

If your Gradle build has suddenly started taking a **very long time**, this guide walks through the most common causes and fixes, especially for **Spring Boot + multi-project** builds.

---

\## Step 1: Identify Where the Time Is Going

Run:

```bash
./gradlew build --profile
```

After the build finishes, open the generated report:

```
build/reports/profile/profile-*.html
```

Check where the time is being spent:
- **Configuration phase** → see \[Configuration Slowness](#configuration-slowness)
- **Dependency resolution** → see \[Dependency Resolution Issues](#dependency-resolution-issues)
- **Task execution** → normal if compiling large projects

---

\## Step 2: Common Causes (Most Likely First)

---

\### 1. Gradle Re-downloading Dependencies Every Build

This can happen if:
- Gradle cache is corrupted
- `--refresh-dependencies` was used recently
- Network / VPN / DNS is unstable
- Gradle daemon is not being reused

**Fix:**

```bash
./gradlew --stop
rm -rf ~/.gradle/caches
rm -rf ~/.gradle/daemon
```

Then run the build again and allow it to fully complete.

---

\### 2. Gradle Daemon Is Disabled or Not Reused

Without the daemon, every build starts a new JVM (very slow).

Check daemon status:

```bash
./gradlew --status
```

Enable daemon in `gradle.properties`:

```properties
org.gradle.daemon=true
```

---

\### 3. Gradle Version Too Old for Spring Boot 3+

Spring Boot 3.x requires **newer Gradle versions**.

Check:

```bash
./gradlew -v
```

If Gradle < 7.5, upgrade the wrapper:

```bash
./gradlew wrapper --gradle-version 8.5
```

---

\### 4. Multi-Project Builds Without Parallelism

Multi-module projects can be very slow if Gradle runs projects sequentially.

Add to `gradle.properties`:

```properties
org.gradle.parallel=true
org.gradle.configureondemand=true
```

This can dramatically reduce build time.

---

\### 5. Configuration-Time Logic Is Slow

Gradle executes build scripts **every build**, even if nothing changes.

Red flags:
- Heavy logic in `build.gradle`
- File system scanning
- Dynamic dependency resolution
- Complex logic in `buildSrc`

Test configuration speed:

```bash
./gradlew tasks
```

If this is slow, configuration is the issue.

---

\## Configuration Slowness (High Impact Fix)

Enable the configuration cache:

```properties
org.gradle.configuration-cache=true
```

Notes:
- First build will still be slow
- Subsequent builds are much faster
- Gradle will report anything that prevents caching

---

\## Dependency Resolution Issues

If Gradle appears to hang while resolving dependencies, check network access:

```bash
curl -I https://repo1.maven.org/maven2/
```

If this is slow or fails:
- VPN may be interfering
- Corporate proxy may be misconfigured
- DNS issues can cause extreme delays

---

\## Recommended Baseline Configuration

For Spring Boot + multi-project builds:

```properties
org.gradle.daemon=true
org.gradle.parallel=true
org.gradle.configureondemand=true
org.gradle.caching=true
org.gradle.configuration-cache=true
```

Environment:
- Java 17+
- Gradle 8.x wrapper

---

\## If This Started Recently

Almost always caused by one of:
- Java version change
- Gradle wrapper update
- VPN or proxy enabled
- New subproject added
- New Gradle plugin introduced

Identify what changed since the last fast build.

---

\## Quick Checklist

1. Run `./gradlew build --profile`
2. Verify Gradle daemon is running
3. Clear Gradle caches if dependencies hang
4. Enable parallelism and configuration cache
5. Check network connectivity to Maven Central

---

\## Getting More Detail

For deeper diagnostics:

```bash
./gradlew build --info
```

or

```bash
./gradlew build --debug
```

---

\*This guide is intended for development environments. CI environments may require different tuning.\*
