#!/usr/bin/env bash
set -euo pipefail


#*Tags:
# Shell: bash pwsh zsh fish
# Platforms: Mac Linux Server WSL
# Distros: Ubuntu Debian Fedora Arch NixOS RaspberryPi Opensuse
# Architectures: ARM64/AArch64 x86_64
# DisplayServers: Wayland x11
# PackageManagers: apt dnf pacman zypper nix brew flatpak snap go python
# DesktopEnvironments: Gnome kde hyprland xfce
# Categories: utility development customization productivity Backups
# Privileges: admin user




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


