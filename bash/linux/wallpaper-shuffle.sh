#!/usr/bin/env bash

set -euo pipefail

# ===============================
# Configuration
# ===============================
REPO_URL="https://github.com/rocketpowerinc/assets.git"
BRANCH="main"
BASE_DIR="$HOME/Pictures/Wallpapers"
RESOLUTION="3840x2160"
DEST="$BASE_DIR/$RESOLUTION"
SPARSE_PATH="wallpapers/$RESOLUTION"
SLIDESHOW_DELAY=5

# ===============================
# Ensure Wallpapers Exist
# ===============================

if [ ! -d "$DEST" ]; then
    echo "📦 $RESOLUTION not found. Cloning..."

    mkdir -p "$BASE_DIR"
    cd "$BASE_DIR"

    git init temp-assets
    cd temp-assets

    git remote add origin "$REPO_URL"
    git config core.sparseCheckout true
    echo "$SPARSE_PATH/*" >> .git/info/sparse-checkout

    git pull origin "$BRANCH"

    mv "$SPARSE_PATH" "$BASE_DIR/"
    cd "$BASE_DIR"
    rm -rf temp-assets

    echo "✅ Clone complete."
else
    echo "✔ Wallpapers already exist."
fi

# ===============================
# Select Folder (gum only first run)
# ===============================

CACHE_FILE="$HOME/.cache/wallpaper-shuffle-folder"
mkdir -p "$(dirname "$CACHE_FILE")"

if [ ! -f "$CACHE_FILE" ]; then
    echo
    echo "🎨 Choose a wallpaper category:"

    mapfile -t SUBFOLDERS < <(
        find "$DEST" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | sort
    )

    if [ "${#SUBFOLDERS[@]}" -eq 0 ]; then
        echo "❌ No subfolders found."
        exit 1
    fi

    SELECTED=$(printf "%s\n" "${SUBFOLDERS[@]}" | gum choose --header="Select Wallpaper Folder")

    echo "$SELECTED" > "$CACHE_FILE"
else
    SELECTED=$(cat "$CACHE_FILE")
fi

DIR="$DEST/$SELECTED"

echo "🖼️ Using folder: $SELECTED"
echo "🚀 Starting slideshow..."

# ===============================
# Slideshow Loop (Foreground)
# ===============================

while true; do
    img=$(find "$DIR" -type f \( \
        -iname "*.jpg" -o \
        -iname "*.jpeg" -o \
        -iname "*.png" -o \
        -iname "*.webp" \
    \) | shuf -n 1)

    [ -n "$img" ] || continue

    gsettings set org.gnome.desktop.background picture-uri "file://$img"
    gsettings set org.gnome.desktop.background picture-uri-dark "file://$img"

    sleep "$SLIDESHOW_DELAY"
done
