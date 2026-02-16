#!/usr/bin/env bash

set -euo pipefail
unset BOLD

# ===============================
# Configuration
# ===============================
REPO_URL="https://github.com/rocketpowerinc/assets.git"
BRANCH="main"
BASE_DIR="$HOME/Pictures/Wallpapers"
RESOLUTION="3840x2160"
DEST="$BASE_DIR/$RESOLUTION"
SPARSE_PATH="wallpapers/$RESOLUTION"
SLIDESHOW_DELAY=5   # 600 = 10 minutes
PID_FILE="$HOME/.cache/wallpaper-shuffle.pid"

# ===============================
# Utility Functions
# ===============================

is_running() {
    [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null
}

stop_running() {
    if is_running; then
        echo "🛑 Stopping wallpaper shuffle..."
        kill "$(cat "$PID_FILE")" || true
        rm -f "$PID_FILE"
        echo "✅ Stopped."
    else
        echo "✔ No running instance found."
    fi
}

# ===============================
# Handle Commands
# ===============================

case "${1:-start}" in
    stop)
        stop_running
        exit 0
        ;;
    restart)
        stop_running
        ;;
    status)
        if is_running; then
            echo "🟢 Running (PID $(cat "$PID_FILE"))"
        else
            echo "🔴 Not running"
        fi
        exit 0
        ;;
esac

# ===============================
# Clone Only If Missing
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
# Choose Subfolder with gum
# ===============================

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

DIR="$DEST/$SELECTED"

echo
echo "🖼️ Selected: $SELECTED"

# ===============================
# Prevent Duplicate Instances
# ===============================

stop_running

# ===============================
# Start Background Slideshow
# ===============================

echo "🚀 Starting slideshow in background..."

(
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
) > /dev/null 2>&1 &

echo $! > "$PID_FILE"

disown

echo "✅ Wallpaper shuffle running."
echo "   Use: $(basename "$0") stop"
