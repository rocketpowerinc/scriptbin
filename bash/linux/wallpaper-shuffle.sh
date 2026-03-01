#!/usr/bin/env bash

set -euo pipefail
unset BOLD

# ===============================
# Configuration
# ===============================
REPO_URL="https://github.com/rocketpowerinc/assets.git"
BRANCH="main"
ASSETS_DIR="$HOME/Pictures/Assets"
RESOLUTION="3840x2160"
DEST="$ASSETS_DIR/wallpapers/$RESOLUTION"
SLIDESHOW_DELAY=600 # 10 Minutes
SERVICE_PATH="$HOME/.config/systemd/user/wallpaper-shuffle.service"

# ==========================================
# 1. SystemD Service Creation
# ==========================================
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

# ==========================================
# 2. Bootstrap & Selection logic
# ==========================================
# If script is run with --select, it just picks a folder and exits.
# If run with no flags, it sets up the service and exits.
if [[ "${1:-}" != "--run" ]]; then
    if [[ "${1:-}" == "--select" ]]; then
        # We delete the cache so the selection logic in Section 4 triggers
        rm -f "$HOME/.cache/wallpaper-shuffle-folder"
        echo "📂 Opening folder selection..."
    else
        systemctl --user enable --now wallpaper-shuffle
        echo "🚀 Wallpaper shuffle has been enabled and started via systemd."
        exit 0
    fi
fi

# ===============================
# 3. Ensure Wallpapers Exist
# ===============================
if [ ! -d "$DEST" ]; then
    echo "📦 Wallpapers folder not found at $DEST"
    echo "Cloning wallpapers repository..."
    git clone https://github.com/rocketpowerinc/assets.git "$HOME/Pictures/Assets"
    echo "✅ Clone complete."
fi

# ===============================
# 4. Select Folder
# ===============================
CACHE_FILE="$HOME/.cache/wallpaper-shuffle-folder"
mkdir -p "$(dirname "$CACHE_FILE")"

# If we are in selection mode, OR the cache doesn't exist, we run the picker
if [[ "${1:-}" == "--select" ]] || [ ! -f "$CACHE_FILE" ]; then
    mapfile -t SUBFOLDERS < <(find "$DEST" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | sort)

    if [ "${#SUBFOLDERS[@]}" -eq 0 ]; then
        echo "❌ No subfolders found in $DEST"
        exit 1
    fi

    if [ ! -t 0 ] && [[ "${1:-}" != "--select" ]]; then
        SELECTED="${SUBFOLDERS[0]}"
    else
        SELECTED=$(printf "%s\n" "${SUBFOLDERS[@]}" | env -u BOLD gum choose --header="Select Wallpaper Folder")
    fi

    echo "$SELECTED" > "$CACHE_FILE"
    echo "📂 Selected: $SELECTED"

    # CRITICAL: If we just wanted to select, exit now so we don't start a second loop!
    if [[ "${1:-}" == "--select" ]]; then
        exit 0
    fi
else
    SELECTED=$(cat "$CACHE_FILE")
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