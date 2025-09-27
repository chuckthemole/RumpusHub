# RumpusHub Monorepo

Welcome to **RumpusHub**, the central monorepo that contains all major components of the Rumpus platform.

This repository is designed to unify development, dependency management, and deployment workflows across multiple interrelated modules used by the Rumpus project.

---

## Repository Structure

RumpusHub includes the following subprojects:

- **`common/`** – Shared Java utilities, core classes, and base functionality.
- **`rumpus/`** – Main application logic and platform-specific implementation.
- **`admin/`** – Administrative tools and interfaces for managing the platform.
- **`buildSrc/`** – Custom Gradle build logic and scripts shared across modules.

Each subproject has its own `build.gradle` file and follows a modular design to support reuse and maintainability.

---

## Monorepo?

The monorepo approach helps:

- Centralize configuration and environment management (e.g., `.env`, publishing credentials).
- Simplify inter-module dependencies (e.g., `common` used by `rumpus`).
- Facilitate atomic commits and version control across modules.
- Reduce duplication and improve visibility into the overall system architecture.

---

## Development Setup

1. Clone the repo:
   ```bash
   git clone https://github.com/chuckthemole/RumpusHub.git
   cd RumpusHub
