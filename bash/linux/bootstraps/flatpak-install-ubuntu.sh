#!/usr/bin/env bash

###############################################################################
# Flatpak + Flathub Installer (Ubuntu / Debian)
#
# DESCRIPTION:
# Ensures Flatpak is installed and configures the Flathub repository.
#
# BEHAVIOR:
#   1. Verifies system uses apt (Ubuntu/Debian).
#   2. Installs Flatpak if missing.
#   3. Adds Flathub remote if not already configured.
#
# SAFE:
#   - Idempotent
#   - Non-interactive
#   - Uses strict bash mode
#
###############################################################################

set -euo pipefail

FLATHUB_URL="https://dl.flathub.org/repo/flathub.flatpakrepo"

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo "🔎 Verifying system compatibility..."

if ! command_exists apt; then
    echo "❌ This script requires Ubuntu or Debian (apt package manager)."
    exit 1
fi

echo "🔍 Checking for Flatpak..."

if command_exists flatpak; then
    echo "✅ Flatpak is already installed."
else
    echo "📦 Flatpak not found. Installing..."
    sudo apt update
    sudo apt install -y flatpak
    echo "✅ Flatpak installation complete."
fi

echo "🔍 Checking Flathub repository..."

if flatpak remote-list --columns=name 2>/dev/null | grep -qx "flathub"; then
    echo "✅ Flathub repository already configured."
else
    echo "➕ Adding Flathub repository..."
    sudo flatpak remote-add --if-not-exists flathub "$FLATHUB_URL"
    echo "✅ Flathub added successfully."
fi

echo "🎉 Flatpak setup complete."
echo "ℹ️ You may need to log out and back in for Flatpak apps to appear in your launcher."