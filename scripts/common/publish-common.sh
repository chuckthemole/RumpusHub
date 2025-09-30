#!/bin/bash
#
# publish-common.sh
#
# A publishing tool for the `common` module of the Rumpus project.
#
# Features:
# - Publishes to Maven Local, a test repo, or GitHub Packages.
# - Only bumps the version number when publishing to GitHub Packages
#   (so public releases always use a new version).
# - Reads and updates the version stored in `gradle/rumpus.versions.toml`.
# - Supports semantic version bumping (major | minor | patch).
#
# Usage:
#   ./publish-common.sh [local | test | github | all] [major | minor | patch]
#
# Examples:
#   ./publish-common.sh local
#       → publishes locally, does NOT bump version
#
#   ./publish-common.sh github
#       → bumps patch version, updates rumpus.versions.toml, publishes to GitHub
#
#   ./publish-common.sh github minor
#       → bumps minor version, updates rumpus.versions.toml, publishes to GitHub
#
#   ./publish-common.sh all major
#       → bumps major version, updates rumpus.versions.toml, publishes everywhere
#

set -euo pipefail

# -----------------------------------------------------------------------------
# Determine repository root (script can be run from any directory)
# -----------------------------------------------------------------------------
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." &> /dev/null && pwd)

# Paths
VERSION_FILE="$REPO_ROOT/gradle/rumpus.versions.toml"
MODULE="common"
GRADLE_CMD="$REPO_ROOT/gradlew"

# -----------------------------------------------------------------------------
# Function to print section headers
# -----------------------------------------------------------------------------
section() {
  echo
  echo "============================"
  echo "$1"
  echo "============================"
}

# -----------------------------------------------------------------------------
# Extract current version from rumpus.versions.toml
# -----------------------------------------------------------------------------
get_current_version() {
  grep -E '^common\s*=' "$VERSION_FILE" | head -n1 | cut -d'"' -f2
}

# -----------------------------------------------------------------------------
# Bump a semantic version string
# -----------------------------------------------------------------------------
bump_version() {
  local current_version=$1
  local bump_type=$2

  IFS='.' read -r major minor patch <<< "$current_version"

  case "$bump_type" in
    major)
      major=$((major + 1))
      minor=0
      patch=0
      ;;
    minor)
      minor=$((minor + 1))
      patch=0
      ;;
    patch|*)
      patch=$((patch + 1))
      ;;
  esac

  echo "${major}.${minor}.${patch}"
}

# -----------------------------------------------------------------------------
# Update rumpus.versions.toml with new version
# -----------------------------------------------------------------------------
set_new_version() {
  local new_version=$1

  if grep -q '^[[:space:]]*common[[:space:]]*=' "$VERSION_FILE"; then
    awk -v ver="$new_version" '
      BEGIN { updated=0 }
      /^[[:space:]]*common[[:space:]]*=/ && updated==0 {
        print "common = \"" ver "\""
        updated=1
        next
      }
      { print }
    ' "$VERSION_FILE" > "$VERSION_FILE.tmp" && mv "$VERSION_FILE.tmp" "$VERSION_FILE"

    echo "Updated $VERSION_FILE to version $new_version"
  else
    echo "ERROR: Could not find 'common' version line in $VERSION_FILE"
    exit 1
  fi
}

# -----------------------------------------------------------------------------
# Validate input
# -----------------------------------------------------------------------------
if [ $# -lt 1 ]; then
  echo "Usage: ./publish-common.sh [local | test | github | all] [major|minor|patch]"
  exit 1
fi

PUBLISH_TARGET=$1
BUMP_TYPE=${2:-patch} # default to patch bump

# -----------------------------------------------------------------------------
# Get current version from TOML
# -----------------------------------------------------------------------------
CURRENT_VERSION=$(get_current_version)
NEW_VERSION=$CURRENT_VERSION

# -----------------------------------------------------------------------------
# Decide whether to bump
# -----------------------------------------------------------------------------
if [[ "$PUBLISH_TARGET" == "github" || "$PUBLISH_TARGET" == "all" ]]; then
  NEW_VERSION=$(bump_version "$CURRENT_VERSION" "$BUMP_TYPE")
  set_new_version "$NEW_VERSION"

  section "Version bumped"
  echo "Old version: $CURRENT_VERSION"
  echo "New version: $NEW_VERSION"
else
  section "Warning"
  echo "Publishing to $PUBLISH_TARGET does NOT bump version."
  echo "Using currently declared version: $CURRENT_VERSION"
fi

# -----------------------------------------------------------------------------
# Group ID path for verifying Maven local publication
# -----------------------------------------------------------------------------
GROUP_ID_PATH="com/rumpushub/common/common/${NEW_VERSION}"

# -----------------------------------------------------------------------------
# Perform publishing
# -----------------------------------------------------------------------------
case "$PUBLISH_TARGET" in
  local)
    section "Publishing to Maven Local"
    "$GRADLE_CMD" :${MODULE}:publishToMavenLocal
    section "Published files in Maven Local"
    ls -al ~/.m2/repository/$GROUP_ID_PATH || echo "No files found"
    ;;
  test)
    section "Publishing to Local TestRepo"
    "$GRADLE_CMD" :${MODULE}:publishGprPublicationToGitHubPackagesRepository -PcommonVersion="$NEW_VERSION"
    ;;
  github)
    section "Publishing to GitHub Packages"
    "$GRADLE_CMD" :${MODULE}:publishGprPublicationToGitHubPackagesRepository -PcommonVersion="$NEW_VERSION"
    ;;
  all)
    section "Publishing to Maven Local"
    "$GRADLE_CMD" :${MODULE}:publishToMavenLocal

    section "Publishing to Local TestRepo"
    "$GRADLE_CMD" :${MODULE}:publishGprPublicationToGitHubPackagesRepository -PcommonVersion="$NEW_VERSION"

    section "Publishing to GitHub Packages"
    "$GRADLE_CMD" :${MODULE}:publishGprPublicationToGitHubPackagesRepository -PcommonVersion="$NEW_VERSION"

    section "Published files in Maven Local"
    ls -al ~/.m2/repository/$GROUP_ID_PATH || echo "No files found"
    ;;
  *)
    echo "Invalid option: $PUBLISH_TARGET"
    echo "Usage: ./publish-common.sh [local | test | github | all] [major|minor|patch]"
    exit 1
    ;;
esac

echo
echo "Done publishing!"
