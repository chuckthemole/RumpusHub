#!/bin/bash

# Exit immediately if any command fails
set -e

# Function to print section headers
section() {
  echo
  echo "============================"
  echo "$1"
  echo "============================"
}

# Define group ID path for Maven local verification
GROUP_ID_PATH="com/rumpushub/common/common/0.1.0"

# Check for user input
if [ -z "$1" ]; then
  echo "Usage: ./publish-common.sh [local | test | github | all]"
  exit 1
fi

# Handle publishing options
case "$1" in
  local)
    section "Publishing to Maven Local"
    ./gradlew :common:publishToMavenLocal
    section "Published files in Maven Local"
    ls -al ~/.m2/repository/$GROUP_ID_PATH || echo "No files found at ~/.m2/repository/$GROUP_ID_PATH"
    ;;
  test)
    section "Publishing to Local TestRepo"
    ./gradlew :common:publishGprPublicationToGitHubPackagesRepository
    ;;
  github)
    section "Publishing to GitHub Packages"
    ./gradlew :common:publishGprPublicationToGitHubPackagesRepository
    ;;
  all)
    section "Publishing to Maven Local"
    ./gradlew :common:publishToMavenLocal
    section "Publishing to Local TestRepo"
    ./gradlew :common:publishGprPublicationToGitHubPackagesRepository
    section "Publishing to GitHub Packages"
    ./gradlew :common:publishGprPublicationToGitHubPackagesRepository
    section "Published files in Maven Local"
    ls -al ~/.m2/repository/$GROUP_ID_PATH || echo "No files found at ~/.m2/repository/$GROUP_ID_PATH"
    ;;
  *)
    echo "Invalid option: $1"
    echo "Usage: ./publish-common.sh [local | test | github | all]"
    exit 1
    ;;
esac

echo
echo "Done publishing!"
