#!/usr/bin/env bash

#*Tags:
# Name: <script name>.sh
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



############* Temp CLone Repository Snippet ############
# Config
REPO_URL="https://github.com/rocketpowerinc/appbundles.git"
DOWNLOAD_PATH="$HOME/Downloads/Temp/appbundles"

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

echo -e '\033[0;32mTemp folder cloned/refreshed successfully!\033[0m'



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
