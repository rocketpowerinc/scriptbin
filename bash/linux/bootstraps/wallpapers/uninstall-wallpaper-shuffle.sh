#!/usr/bin/env bash

set -euo pipefail

SERVICE_NAME="wallpaper-shuffle"
SERVICE_PATH="$HOME/.config/systemd/user/wallpaper-shuffle.service"
SCRIPT_PATH="$HOME/.local/bin/wallpaper-shuffle"
CACHE_FILE="$HOME/.cache/wallpaper-shuffle-folder"

# Stop and disable the systemd service
systemctl --user stop "$SERVICE_NAME" 2>/dev/null || true
systemctl --user disable "$SERVICE_NAME" 2>/dev/null || true

# Remove the systemd service file
if [ -f "$SERVICE_PATH" ]; then
    rm -f "$SERVICE_PATH"
    echo "✅ Removed systemd service file: $SERVICE_PATH"
fi

# Remove the installed script
if [ -f "$SCRIPT_PATH" ]; then
    rm -f "$SCRIPT_PATH"
    echo "✅ Removed script: $SCRIPT_PATH"
fi

# Remove the cache file
if [ -f "$CACHE_FILE" ]; then
    rm -f "$CACHE_FILE"
    echo "✅ Removed cache file: $CACHE_FILE"
fi

# Optionally remove the wallpapers directory (uncomment if desired)
# WALLPAPER_DIR="$HOME/Pictures/Assets"
# if [ -d "$WALLPAPER_DIR" ]; then
#     rm -rf "$WALLPAPER_DIR"
#     echo "✅ Removed wallpapers directory: $WALLPAPER_DIR"
# fi

systemctl --user daemon-reload

echo "✅ Wallpaper shuffle uninstalled."
