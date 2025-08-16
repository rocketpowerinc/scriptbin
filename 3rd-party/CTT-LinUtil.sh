#!/usr/bin/env bash
set -euo pipefail


#*Tags:
# Name: CTT-LinuxUtil.sh
# Shell: bash
# Platforms: Linux Server WSL
# Hardware: RaspberryPi Steamdeck ROG-Ally ROG-Desktop ROG-Laptop ThinkPad Android
# Distros: Ubuntu Debian Fedora Arch NixOS Opensuse Atomic
# Architectures: ARM64/AArch64 x86_64
# DisplayServers: Wayland x11
# Framework: Gum
# PackageManagers: apt dnf pacman
# DesktopEnvironments: Gnome kde hyprland xfce
# Type: Bootstrap Appbundle Utility
# Categories: development customization
# Privileges: admin
# 3rd-party: Titus


#*############################################


# Ensure gum is available
if ! command -v gum >/dev/null 2>&1; then
  echo "gum is required (https://github.com/charmbracelet/gum)."
  exit 1
fi

# Menu
choice=$(gum choose \
  "Stable Branch (Recommended)" \
  "Dev Branch" \
  "Cancel")

case "${choice:-}" in
  "Stable Branch (Recommended)")
    cmd='curl -fsSL https://christitus.com/linux | sh'
    ;;
  "Dev Branch")
    cmd='curl -fsSL https://christitus.com/linuxdev | sh'
    ;;
  *)
    echo "Canceled."
    exit 0
    ;;
esac

# Safety confirmation (remove if you want instant execution)
if gum confirm "Run: $cmd ?"; then
  bash -lc "$cmd"
else
  echo "Aborted."
fi