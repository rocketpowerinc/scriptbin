#!/usr/bin/env bash
REPO_URL="https://github.com/rocketpowerinc/assets.git"
DEST="$HOME/Pictures/Assets"
BRANCH="main"

if [ ! -d "$DEST/.git" ]; then
    echo "📦 Cloning wallpapers repo to $DEST..."
    git clone "$REPO_URL" "$DEST"
    echo "✅ Clone complete."
else
    echo "🔄 Repo exists. Pulling latest wallpapers..."
    cd "$DEST"
    git pull origin "$BRANCH"
    echo "✅ Wallpapers updated."
fi