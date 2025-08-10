#!/usr/bin/env bash
set -euo pipefail


#*Tags:
# Languages: bash pwsh zsh fish
# Platforms: Linux Mac Server WSL
# Distros: Ubuntu Debian Fedora Arch NixOS RaspberryPi
# Architectures: ARM64/AArch64 x86_64
# DisplayServers: Wayland x11
# PackageManagers: apt dnf pacman nix brew
# DesktopEnvironments: Gnome kde hyprland xfce
# Categories: utility development git



############* Temp CLone Repository Snippet ############
# Config
REPO_URL="https://github.com/rocketpowerinc/xxx.git"
DOWNLOAD_PATH="$HOME/Downloads/Temp/xxx"

# Make sure parent directory exists
mkdir -p "$(dirname "$DOWNLOAD_PATH")"

# Remove old copy if it exists
if [ -d "$DOWNLOAD_PATH" ]; then
    echo "Removing old folder: $DOWNLOAD_PATH"
    rm -rf "$DOWNLOAD_PATH"
fi

# Clone repository
echo "Cloning $REPO_URL into $DOWNLOAD_PATH..."
git clone "$REPO_URL" "$DOWNLOAD_PATH"

echo "Done!"



############* Temp CLone Repository Snippet ############
# Config
REPO_URL="https://github.com/rocketpowerinc/xxx.git"
DOWNLOAD_PATH="$HOME/Downloads/Temp/xxx"

# Make sure parent directory exists
mkdir -p "$(dirname "$DOWNLOAD_PATH")"

# Remove old copy if it exists
if [ -d "$DOWNLOAD_PATH" ]; then
    echo "Removing old folder: $DOWNLOAD_PATH"
    rm -rf "$DOWNLOAD_PATH"
fi

# Clone repository
echo "Cloning $REPO_URL into $DOWNLOAD_PATH..."
git clone "$REPO_URL" "$DOWNLOAD_PATH"

echo "Done!"
