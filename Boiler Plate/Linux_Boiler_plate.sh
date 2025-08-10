#!/usr/bin/env bash
set -euo pipefail

#*Tags
#bash #pwsh #zsh #fish
#Linux #Mac #Server #WSL
#Ubuntu #Debian #Fedora #Arch #NixOS #RaspberryPi
#ARM64/AArch64 #x86_64
#Wayland #x11 
#apt #dnf #pacman #nix #brew
#Gnome #kde #hyperland #xfce




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
