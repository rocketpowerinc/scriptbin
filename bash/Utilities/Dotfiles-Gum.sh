#!/usr/bin/env bash


#*Tags:
# Name: Dotfiles-Gum.sh
# Shell: bash zsh fish
# Platforms: Mac Linux Server WSL Docker
# Hardware: RaspberryPi Steamdeck ROG-Ally ROG-Desktop ROG-Laptop ThinkPad Asus Razor Logitech Nvidia Android
# Distros: Ubuntu Debian Fedora Arch NixOS Opensuse Atomic
# Architectures: ARM64/AArch64 x86_64
# DisplayServers: Wayland x11
# Framework: Gum
# PackageManagers: apt dnf pacman zypper nix brew flatpak snap go python
# DesktopEnvironments: Gnome kde hyprland xfce
# Type: Bootstrap Appbundle Utility
# Categories: development customization
# Privileges: admin
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

  # Find all .sh and .ps1 script files recursively and create relative paths for display
  declare -a all_files
  while IFS= read -r -d '' file; do
    if [ -f "$file" ]; then
      # Check if file has .sh or .ps1 extension
      case "${file,,}" in
        *.sh|*.ps1)
          relative_path="${file#$DOWNLOAD_PATH/}"
          all_files+=("$relative_path")
          ;;
      esac
    fi
  done < <(find "$DOWNLOAD_PATH" -type f -print0 2>/dev/null | sort -z)

  if [ ${#all_files[@]} -eq 0 ]; then
    echo -e "${YELLOW}No .sh or .ps1 script files found in $DOWNLOAD_PATH${RESET}"
    break
  fi

  echo "Found ${#all_files[@]} script files (.sh and .ps1)"

  # Use gum choose to select from the list
  selected_relative=$(printf '%s\n' "${all_files[@]}" | gum choose --height 20)

  if [ -z "${selected_relative:-}" ]; then
    echo -e "${YELLOW}No file selected. Exiting...${RESET}"
    break
  fi

  # Get the full path of the selected file
  selected_file="$DOWNLOAD_PATH/$selected_relative"

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
      *) continue;;
    esac
  elif [[ "$ext" == "ps1" ]]; then
    if command -v pwsh >/dev/null 2>&1; then
      echo -e "${CYAN}Running PowerShell script: $selected_file${RESET}"
      pwsh -File "$selected_file"
      echo -e "${GREEN}Script execution completed.${RESET}"
    elif command -v powershell >/dev/null 2>&1; then
      echo -e "${CYAN}Running PowerShell script: $selected_file${RESET}"
      powershell -File "$selected_file"
      echo -e "${GREEN}Script execution completed.${RESET}"
    else
      echo -e "${YELLOW}PowerShell not found; cannot execute .ps1 files automatically.${RESET}"
    fi
    echo
    printf "%s" "Do you want to run/select another script? (Y/n) "
    read -r answer || answer=""
    case "${answer:-}" in
      [Nn]) break;;
      *) continue;;
    esac
  else
    echo -e "${GREEN}Selected file: $selected_file${RESET}"
    echo -e "${YELLOW}This is not a Bash script (.sh), so it won't be executed automatically.${RESET}"
    echo
    printf "%s" "Do you want to select another file? (Y/n) "
    read -r answer || answer=""
    case "${answer:-}" in
      [Nn]) break;;
      *) continue;;
    esac
  fi
done
