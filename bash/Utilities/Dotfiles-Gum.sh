#!/usr/bin/env bash
set -euo pipefail

#*Tags:
# Name: Dotfiles-Gum.sh
# Shell: bash pwsh zsh fish
# Platforms: Mac Linux Server WSL Docker
# Hardware: RaspberryPi Steamdeck ROG-Ally ROG-Desktop ROG-Laptop ThinkPad Asus Razor Logitech Nvidia Android
# Distros: Ubuntu Debian Fedora Arch NixOS Opensuse Atomic
# Architectures: ARM64/AArch64 x86_64
# DisplayServers: Wayland x11
# Framework: Gum
# PackageManagers: apt dnf pacman zypper nix brew flatpak snap go python
# DesktopEnvironments: Gnome kde hyprland xfce
# Type: Bootstrap Appbundle Utility
# Categories: development virtualization containerization customization productivity backups bookmarks gaming emulation family doomsday Security Privacy
# Privileges: admin user
# Application: tailscale vim github
# ThirdParty: Titus
#*############################################



# --- deps check ---------------------------------------------------------------
need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dep: $1"; exit 1; }; }
need git
need gum

# --- config -------------------------------------------------------------------
REPO_URL="https://github.com/rocketpowerinc/dotfiles.git"
DOWNLOAD_PATH="$HOME/Downloads/Temp/dotfiles"
PARENT_DIR="$(dirname "$DOWNLOAD_PATH")"

# --- colors -------------------------------------------------------------------
# (works in most terminals)
GREEN="\033[0;32m"; YELLOW="\033[0;33m"; MAGENTA="\033[0;35m"; BLUE="\033[0;34m"; CYAN="\033[0;36m"; RESET="\033[0m"

# --- prepare destination ------------------------------------------------------
mkdir -p "$PARENT_DIR"

if [[ -d "$DOWNLOAD_PATH" ]]; then
  echo -e "${YELLOW}Removing old folder: $DOWNLOAD_PATH${RESET}"
  rm -rf -- "$DOWNLOAD_PATH"
fi

# --- clone --------------------------------------------------------------------
echo -e "${CYAN}Cloning $REPO_URL into $DOWNLOAD_PATH...${RESET}"
git clone --depth=1 "$REPO_URL" "$DOWNLOAD_PATH"

# --- clean extras -------------------------------------------------------------
[[ -d "$DOWNLOAD_PATH/.vscode"      ]] && { echo -e "${YELLOW}Removing .vscode directory...${RESET}";      rm -rf -- "$DOWNLOAD_PATH/.vscode"; }
[[ -f "$DOWNLOAD_PATH/README.md"    ]] && { echo -e "${YELLOW}Removing readme.md file...${RESET}";         rm -f  -- "$DOWNLOAD_PATH/README.md"; }
[[ -d "$DOWNLOAD_PATH/.git"         ]] && { echo -e "${YELLOW}Removing .git directory...${RESET}";         rm -rf -- "$DOWNLOAD_PATH/.git"; }
[[ -d "$DOWNLOAD_PATH/.boilerplate" ]] && { echo -e "${YELLOW}Removing .boilerplate directory...${RESET}"; rm -rf -- "$DOWNLOAD_PATH/.boilerplate"; }

echo -e "${GREEN}Temp Dotfiles folder cloned/refreshed successfully!${RESET}"
echo -e "${MAGENTA}Please select a pwr-path script to place your selected dotfile configs${RESET}"
echo -e "${BLUE}Press Enter to continue...${RESET}"
read -r dummy

# --- main loop ----------------------------------------------------------------
while :; do
  clear

  # Use gum to pick a file within the cloned dir
  selected_file="$(gum file --height 20 "$DOWNLOAD_PATH" || true)"

  if [ -z "${selected_file:-}" ]; then
    echo -e "${YELLOW}No file selected. Exiting...${RESET}"
    break
  fi

  # Determine extension (lowercased)
  filename="${selected_file##*/}"
  ext="${filename##*.}"
  # lowercase in a portable way (works on older bash: e.g. macOS /bin/bash)
  ext="$(printf '%s' "$ext" | tr '[:upper:]' '[:lower:]')"

  if [[ "$ext" == "sh" ]]; then
    if command -v bash >/dev/null 2>&1; then
      echo -e "${CYAN}Running Bash script: $selected_file${RESET}"
      bash -- "$selected_file"
      echo -e "${GREEN}Script execution completed.${RESET}"
    else
      echo -e "${YELLOW}bash not found; cannot execute .sh files automatically.${RESET}"
    fi
    echo
    printf "%s" "Do you want to run/select another script? (Y/n) "
    read -r answer || answer=""
    case "${answer:-}" in
      [Nn]) break;;
    esac
  else
    echo -e "${GREEN}Selected file: $selected_file${RESET}"
    echo -e "${YELLOW}This is not a Bash script (.sh), so it won't be executed automatically.${RESET}"
    echo
    printf "%s" "Do you want to select another file? (Y/n) "
    read -r answer || answer=""
    case "${answer:-}" in
      [Nn]) break;;
    esac
  fi
done
