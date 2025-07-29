#!/usr/bin/env bash

# Make sure gum is installed
if ! command -v gum &> /dev/null; then
  echo "Error: gum is not installed." >&2
  exit 1
fi

# List of available Flatpak apps
apps=(
  "org.kde.marknote - KDE Marknote"
  "io.github.zefr0x.hashes - Hashes"
  "io.github.bytezz.IPLookup - IPLookup"
)

# Use gum to select which apps to install
selected=$(printf "%s\n" "${apps[@]}" | gum choose --no-limit --header="Select Flatpak apps to install:")

# Exit if nothing was selected
if [ -z "$selected" ]; then
  echo "No apps selected. Exiting."
  exit 0
fi

# Loop through selected apps and install each
while read -r line; do
  app_id=$(echo "$line" | awk '{print $1}')
  echo "Installing $app_id..."
  flatpak install -y flathub "$app_id"
done <<< "$selected"
