#!/usr/bin/env bash
set -euo pipefail

#*Tags:
# Name: clipcascade-install-arch.sh
# Shell: bash
# Platforms: Linux
# Distros: Arch
# PackageManagers: pacman
# Type: Bootstrap
# Application: ClipCascade

echo "==> ClipCascade installer starting (Arch Linux)..."

# Install Dependencies
echo "==> Installing dependencies via pacman..."
sudo pacman -Syu --needed --noconfirm \
    base-devel \
    python \
    python-pip \
    tk \
    python-gobject \
    gtk3 \
    xdg-utils \
    ffmpeg \
    freetype2 \
    lcms2 \
    libjpeg-turbo \
    libtiff \
    libwebp \
    openjpeg2 \
    zlib \
    libxcb \
    xclip \
    wl-clipboard \
    dunst \
    wget \
    unzip

PYTHON_BIN="python"
if pacman -Si python313 >/dev/null 2>&1; then
    echo "==> Installing python313 for better Pillow compatibility..."
    sudo pacman -S --needed --noconfirm python313
fi

if command -v python3.13 >/dev/null 2>&1; then
    PYTHON_BIN="python3.13"
fi

echo "==> Using Python interpreter: $PYTHON_BIN"

APP_DIR="$HOME/Downloads/ClipCascade"
ZIP_FILE="/tmp/ClipCascade_Linux.zip"
SERVICE_FILE="$HOME/.config/systemd/user/clipcascade.service"

# Clean old install
echo "==> Cleaning old installation..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR"

echo "==> Downloading latest release..."
wget -q --show-progress -O "$ZIP_FILE" \
"https://github.com/Sathvik-Rao/ClipCascade/releases/latest/download/ClipCascade_Linux.zip"

echo "==> Extracting..."
unzip -q "$ZIP_FILE" -d "$APP_DIR"

# Flatten nested folder if present
if [ -d "$APP_DIR/ClipCascade" ]; then
    echo "==> Flattening folder structure..."
    mv "$APP_DIR/ClipCascade/"* "$APP_DIR/"
    rm -rf "$APP_DIR/ClipCascade"
fi

cd "$APP_DIR"

if [ ! -f "requirements.txt" ]; then
    echo "ERROR: requirements.txt not found."
    exit 1
fi

echo "==> Creating virtual environment..."
"$PYTHON_BIN" -m venv .venv --system-site-packages

echo "==> Installing Python dependencies..."
"$APP_DIR/.venv/bin/pip" install --upgrade pip setuptools wheel

PYTHON_MM="$($APP_DIR/.venv/bin/python -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"

if [ "$PYTHON_MM" = "3.14" ]; then
    echo "==> Python 3.14 detected; using system Pillow to avoid source build failure..."
    sudo pacman -S --needed --noconfirm python-pillow python-av

    TMP_REQ="$(mktemp)"
    grep -Evi '^[[:space:]]*(pillow|av)([[:space:]]*[<>=!~].*)?[[:space:]]*$' requirements.txt > "$TMP_REQ"

    "$APP_DIR/.venv/bin/pip" install -r "$TMP_REQ"
    rm -f "$TMP_REQ"
    "$APP_DIR/.venv/bin/python" -c 'import PIL; print("Pillow available:", PIL.__version__); import av; print("PyAV available:", av.__version__)'
else
    "$APP_DIR/.venv/bin/pip" install -r requirements.txt
fi

echo "==> Creating systemd user service..."
mkdir -p "$HOME/.config/systemd/user"

cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=ClipCascade Autostart
After=graphical-session.target
Wants=graphical-session.target

[Service]
Type=simple
WorkingDirectory=$APP_DIR
ExecStart=$APP_DIR/.venv/bin/python $APP_DIR/main.py
Restart=always
RestartSec=5

# Wayland/X11 compatibility
Environment=DISPLAY=:0
Environment=XDG_RUNTIME_DIR=/run/user/$(id -u)

[Install]
WantedBy=default.target
EOF

echo "==> Reloading systemd..."
systemctl --user daemon-reload
systemctl --user enable clipcascade.service
systemctl --user restart clipcascade.service

echo "------------------------------------------------"
echo "SUCCESS!"
echo "ClipCascade installed and set to autostart."
echo ""
echo "Check status:"
echo "  systemctl --user status clipcascade"
echo ""
echo "View logs:"
echo "  journalctl --user -u clipcascade -f"
echo "------------------------------------------------"