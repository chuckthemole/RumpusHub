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

# Path to the log file
LOG_FILE="rumpus/src/main/java/com/rumpus/rumpus/log/build.log"

section "Creating log directory and file"

# Create the directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

# Create the log file if it doesn't exist
if [ ! -f "$LOG_FILE" ]; then
  touch "$LOG_FILE"
  echo "Created $LOG_FILE"
else
  echo "$LOG_FILE already exists"
fi

# Set read/write permissions for user and group
chmod 664 "$LOG_FILE"

# Ensure directory has correct permissions (rwx for user, rx for group)
chmod 755 "$(dirname "$LOG_FILE")"

echo "Log file permissions set to:"
ls -l "$LOG_FILE"

section "Init complete!"
