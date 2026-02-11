#!/usr/bin/env bash

#*Tags:
# Name: nixOS-justfile-install.sh
# Shell: bash
# Platforms: Linux
# Hardware: RaspberryPi Steamdeck ROG-Ally ROG-Desktop ROG-Laptop ThinkPad
# Distros: NixOS
# Architectures: ARM64/AArch64 x86_64
# DisplayServers: Wayland
# PackageManagers: nix
# DesktopEnvironments: Gnome kde hyprland xfce
# Type: Bootstrap
# Categories: productivity
# Privileges: admin
# Application: justfile

set -e

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

git clone --depth 1 https://github.com/rocketpowerinc/dotfiles.git "$TMPDIR"

install -m 644 \
  "$TMPDIR/nixos/justfile" \
  "$HOME/justfile"

echo "✔ justfile installed to $HOME/justfile"
