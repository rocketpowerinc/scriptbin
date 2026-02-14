#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# Docker Gum Utility
# ==========================================================

# --- Configuration ---
REPO_URL="https://github.com/rocketpowerinc/docker.git"
DOWNLOAD_PATH="$HOME/Downloads/Temp/Docker"
DOCKER_COMPOSE_DEST="$HOME/Docker/docker-compose"

# --- Dependency Check ---
require() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "❌ Missing dependency: $1"
        exit 1
    fi
}

require git
require gum
require curl

# ==========================================================
# Functions
# ==========================================================

install_docker() {
    echo ">>> Installing Docker..."

    if command -v docker >/dev/null 2>&1; then
        echo "✔ Docker is already installed."
    else
        curl -fsSL https://get.docker.com | sh
        sudo usermod -aG docker "$USER"
        echo "✔ Docker installed successfully."
        echo "⚠ Log out and back in to use docker without sudo."
    fi

    read -rp "Press Enter to continue..."
}

clone_refresh_docker_repo() {
    echo ">>> Cloning Docker repository..."

    rm -rf -- "$DOWNLOAD_PATH"
    mkdir -p "$(dirname "$DOWNLOAD_PATH")"

    git clone "$REPO_URL" "$DOWNLOAD_PATH"

    local src="$DOWNLOAD_PATH/docker-compose"

    if [[ ! -d "$src" ]]; then
        echo "⚠ docker-compose folder not found in repository."
        return
    fi

    mkdir -p "$DOCKER_COMPOSE_DEST"

    echo ">>> Syncing docker-compose folders..."

    for folder in "$src"/*/; do
        [[ -d "$folder" ]] || continue

        local name
        name="$(basename "$folder")"
        local dest="$DOCKER_COMPOSE_DEST/$name"

        mkdir -p "$dest"
        cp -r "$folder"* "$dest" 2>/dev/null || true

        echo "✔ Synced: $name"
    done

    rm -rf -- "$DOWNLOAD_PATH"

    echo "✔ Repository refreshed successfully."
    read -rp "Press Enter to continue..."
}

deploy_containers() {
    clone_refresh_docker_repo

    if [[ ! -d "$DOCKER_COMPOSE_DEST" ]]; then
        echo "❌ Compose directory not found: $DOCKER_COMPOSE_DEST"
        return
    fi

    echo ">>> Searching for docker-compose files..."

    mapfile -t compose_files < <(
        find "$DOCKER_COMPOSE_DEST" \
            \( -name "docker-compose*.yml" -o -name "docker-compose*.yaml" \) \
            -type f | sort -u
    )

    if [[ ${#compose_files[@]} -eq 0 ]]; then
        echo "No docker-compose files found."
        read -rp "Press Enter to continue..."
        return
    fi

    while true; do
        echo ">>> Select a docker-compose file"

        mapfile -t display_files < <(
            printf '%s\n' "${compose_files[@]}" |
            sed "s|$DOCKER_COMPOSE_DEST/||"
        )

        selected=$(printf '%s\n' "${display_files[@]}" | gum choose --height 20)

        [[ -z "$selected" ]] && break

        selected_file="$DOCKER_COMPOSE_DEST/$selected"
        compose_dir="$(dirname "$selected_file")"

        echo ">>> Deploying: $selected"
        (
            cd "$compose_dir"
            sudo docker compose up -d
        )

        echo "✔ Deployment complete."

        read -rp "Deploy another? (Y/n) " again
        [[ -z "$again" || "$again" =~ ^[Yy]$ ]] || break
    done
}

# ==========================================================
# Main Menu Loop
# ==========================================================

while true; do
    choice=$(gum choose \
        "Install Docker" \
        "Install LazyDocker" \
        "Clone/Refresh Docker Repo" \
        "Deploy Containers" \
        "Exit" \
        --cursor "> " \
        --height 15)

    case "$choice" in
        "Install Docker")
            install_docker
            ;;
        "Install LazyDocker")
            echo "LazyDocker installer coming soon..."
            read -rp "Press Enter to continue..."
            ;;
        "Clone/Refresh Docker Repo")
            clone_refresh_docker_repo
            ;;
        "Deploy Containers")
            deploy_containers
            ;;
        "Exit")
            echo "Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid option."
            read -rp "Press Enter to continue..."
            ;;
    esac
done
