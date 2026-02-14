#!/usr/bin/env bash
set -euo pipefail

echo "==> ClipCascade installer starting..."

# Install Dependencies
sudo apt update && sudo apt install -y \
python3 \
python3-pip \
python3-venv \
python3-tk \
python3-gi \
python3-gi-cairo \
gir1.2-gtk-3.0 \
gir1.2-gdk-3.0 \
xclip \
wl-clipboard \
dunst

APP_DIR="$HOME/Downloads/ClipCascade"
ZIP_FILE="/tmp/ClipCascade_Linux.zip"
SERVICE_FILE="$HOME/.config/systemd/user/clipcascade.service"

# Clean old install
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
python3 -m venv .venv

echo "==> Installing dependencies..."
"$APP_DIR/.venv/bin/pip" install --upgrade pip
"$APP_DIR/.venv/bin/pip" install -r requirements.txt

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
ExecStart=$APP_DIR/.venv/bin/python3 $APP_DIR/main.py
Restart=always
RestartSec=5
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
