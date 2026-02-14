#!/usr/bin/env bash


#*Tags:
# Name: Docker-Gum.sh
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

# --- config ---
REPO_URL="https://github.com/rocketpowerinc/docker.git"
DOWNLOAD_PATH="$HOME/Downloads/Temp/Docker"
DOCKER_COMPOSE_DEST="$HOME/Docker/docker-compose"

# --- deps check ---
need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dep: $1"; exit 1; }; }
need git
need gum


# --- clone/refresh docker repo and update docker-compose files ---
clone_refresh_docker_repo() {
  echo ">>> Cloning Docker repo..."
  mkdir -p "$(dirname "$DOWNLOAD_PATH")"
  [ -d "$DOWNLOAD_PATH" ] && { echo "Removing old folder: $DOWNLOAD_PATH"; rm -rf -- "$DOWNLOAD_PATH"; }
  echo "Cloning $REPO_URL into $DOWNLOAD_PATH..."
  git clone "$REPO_URL" "$DOWNLOAD_PATH"
  echo "Repo cloned successfully to $DOWNLOAD_PATH"

  mkdir -p "$DOCKER_COMPOSE_DEST"
  SRC_DOCKER_COMPOSE="$DOWNLOAD_PATH/docker-compose"
  if [ -d "$SRC_DOCKER_COMPOSE" ]; then
    echo "Moving docker-compose files to $DOCKER_COMPOSE_DEST..."
    for folder in "$SRC_DOCKER_COMPOSE"/*/; do
      [ -d "$folder" ] || continue
      dest_folder="$DOCKER_COMPOSE_DEST/$(basename "$folder")"
      mkdir -p "$dest_folder"
      cp -r "$folder"* "$dest_folder" 2>/dev/null || true
      echo "Copied: $(basename "$folder") contents to $dest_folder"
    done
    echo "$(tput setaf 2)Docker-compose files moved successfully (existing files preserved, matching files overwritten)$(tput sgr0)"
  else
    echo "Warning: docker-compose folder not found in cloned repository"
  fi
  echo "Cleaning up temporary folder: $DOWNLOAD_PATH"
  rm -rf -- "$DOWNLOAD_PATH"
  echo "Press Enter to continue..."
  read -r _
}

# --- main gum menu loop ---
while :; do
  choice=$(gum choose \
    "Install Docker" \
    "Install LazyDocker" \
    "Clone/Refresh Docker Repo" \
    "Deploy Containers" \
    "Exit" \
    --cursor "> " \
    --height 15)

  case "$choice" in
    "Install Docker") {
  echo ">>> Installing Docker..."

  if command -v docker >/dev/null 2>&1; then
    echo "Docker is already installed."
  else
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker "$USER"
    echo "Docker installed."
  fi

  echo "Log out and back in to use docker without sudo."
  read -r _
}
      ;;
    "Install LazyDocker")
      echo "Place Holder..."; read -r _
      ;;
    "Clone/Refresh Docker Repo")
      clone_refresh_docker_repo
      ;;
    "Deploy Containers")
      clone_refresh_docker_repo

      echo ">>> Scanning for Docker Compose files..."
      [ -d "$DOCKER_COMPOSE_DEST" ] || { echo "Error: Docker compose directory not found at $DOCKER_COMPOSE_DEST"; continue; }

      # Find all docker-compose files recursively and remove duplicates
      # Use a portable method that works with older bash versions
      compose_files=()
      while IFS= read -r file; do
        compose_files+=("$file")
      done < <(find "$DOCKER_COMPOSE_DEST" \( -name "docker-compose*.yml" -o -name "docker-compose*.yaml" \) -type f 2>/dev/null | sort | uniq)

      if [ ${#compose_files[@]} -eq 0 ]; then
        echo "No docker-compose files found in $DOCKER_COMPOSE_DEST"
        echo "Press Enter to continue..."
        read -r _
        continue
      fi

      echo "Found ${#compose_files[@]} docker-compose files"

      # Create relative paths for display
      declare -a display_files
      for file in "${compose_files[@]}"; do
        relative_path="${file#$DOCKER_COMPOSE_DEST/}"
        display_files+=("$relative_path")
      done

      while :; do
        echo ">>> Selecting Docker Compose file..."
        echo "Available: ${#display_files[@]} docker-compose files"

        # Use gum choose to select from the list
        selected_display=$(printf '%s\n' "${display_files[@]}" | gum choose --height 20)

        [ -n "$selected_display" ] || { echo "No file selected. Returning to main menu..."; break; }

        # Get the full path of the selected file
        selected_file="$DOCKER_COMPOSE_DEST/$selected_display"

        file_name="$(basename "$selected_file")"
        if [[ ! "$file_name" =~ docker-compose.*\.ya?ml$ ]]; then
          echo "Warning: Selected file '$file_name' doesn't appear to be a docker-compose file."
          read -rp "Do you want to continue anyway? (y/N) " confirm
          [[ "$confirm" =~ ^[yY] ]] || { echo "Operation cancelled."; continue; }
        fi
        compose_dir="$(dirname "$selected_file")"
        echo "Deploying containers from: $selected_file"
        echo "Changing directory to: $compose_dir"
        (cd "$compose_dir" && sudo docker compose up -d && echo "Containers deployed successfully!" || echo "Error deploying containers.")
        echo
        read -rp "Do you want to deploy another container? (Y/n) " deploy_another
        [[ -z "$deploy_another" || "$deploy_another" =~ ^[yY] ]] || break
      done
      ;;
    "Exit")
      echo "Goodbye!"
      exit 0
      ;;
    *)
      echo "Invalid option. Press Enter to continue..."; read -r _
      ;;
  esac
done
