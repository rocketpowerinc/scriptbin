#!/usr/bin/env bash

set -euo pipefail
unset BOLD


# ===============================
# 1. Configuration
# ===============================
REPO_URL="https://github.com/rocketpowerinc/assets.git"
BRANCH="main"
ASSETS_DIR="$HOME/Pictures/Assets"
RESOLUTION="3840x2160"
DEST="$ASSETS_DIR/wallpapers/$RESOLUTION"
SLIDESHOW_DELAY=600 # 10 Minutes
SERVICE_PATH="$HOME/.config/systemd/user/wallpaper-shuffle.service"

# ===============================
# 2. Ensure Wallpapers Exist
# ===============================
if [ ! -d "$DEST" ]; then
    echo "❌ Wallpapers folder not found at $DEST"
    echo -e "Please run the \033[38;5;208m\"just download-sync-wallpapers\"\033[0m recipe first."
    read -n 1 -s -r -p "Press any key to continue..."
    exit 1
fi

# ===============================
# 3. SystemD Service Creation
# ===============================
# This creates the service file automatically if it doesn't exist
if [ ! -f "$SERVICE_PATH" ]; then
    echo "⚙️  Creating systemd user service..."
    mkdir -p "$(dirname "$SERVICE_PATH")"

    cat <<EOF > "$SERVICE_PATH"
[Unit]
Description=Wallpaper Shuffle Slideshow
After=graphical-session.target
Wants=graphical-session.target

[Service]
Type=simple
ExecStart=$HOME/.local/bin/wallpaper-shuffle --run
Restart=on-failure
RestartSec=5

[Install]
WantedBy=graphical-session.target
EOF

    systemctl --user daemon-reload
    echo "✅ Service file created at $SERVICE_PATH"
fi




# ===============================
# 4. Folder Selection
# ===============================

CACHE_FILE="$HOME/.cache/wallpaper-shuffle-folder"
mkdir -p "$(dirname "$CACHE_FILE")"
mapfile -t SUBFOLDERS < <(find "$DEST" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | sort)

if [ "${#SUBFOLDERS[@]}" -eq 0 ]; then
    echo "❌ No subfolders found in $DEST"
    exit 1
fi

# Interactive selection ONLY if --select is passed
if [[ "${1:-}" == "--select" ]]; then
    SELECTED=$(printf "%s\n" "${SUBFOLDERS[@]}" | env -u BOLD gum choose --header="Select Wallpaper Folder")
    echo "$SELECTED" > "$CACHE_FILE"
    echo -e "\033[32m📂 Selected: $SELECTED Folder - Use Ctrl + C to exit\033[0m"
    exit 0
fi

# Non-interactive: systemd or manual run

if [ -f "$CACHE_FILE" ]; then
    SELECTED=$(cat "$CACHE_FILE")
else
    # Default to 'Misc' if cache file is missing
    SELECTED="Misc"
    echo "$SELECTED" > "$CACHE_FILE"
    echo -e "\033[33mNo cache file found. Defaulting to: $SELECTED\033[0m"
fi

DIR="$DEST/$SELECTED"

# ===============================
# 5. Slideshow Loop
# ===============================
while true; do
    img=$(find "$DIR" -type f \( \
        -iname "*.jpg" -o \
        -iname "*.jpeg" -o \
        -iname "*.png" -o \
        -iname "*.webp" \
    \) | shuf -n 1)

    if [ -n "$img" ]; then
        gsettings set org.gnome.desktop.background picture-uri "file://$img"
        gsettings set org.gnome.desktop.background picture-uri-dark "file://$img"
    fi

    sleep "$SLIDESHOW_DELAY"
done