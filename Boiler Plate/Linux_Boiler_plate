#!/usr/bin/env bash

# Define the repository URL and the download path
REPO_URL="https://github.com/rocketpowerinc/xxx.git"
DOWNLOAD_PATH="$HOME/Downloads/xxx"

# Clean up
rm -rf "$DOWNLOAD_PATH"

# Clone the repository
git clone "$REPO_URL" "$DOWNLOAD_PATH" || show_error "Failed to clone the repository."

# Clean up
rm -rf "$DOWNLOAD_PATH"