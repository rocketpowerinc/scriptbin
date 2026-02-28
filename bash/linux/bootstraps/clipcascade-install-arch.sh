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
echo "==> Installing base dependencies via pacman..."
sudo pacman -Syu --noconfirm python python-pip python-gobject xclip wl-clipboard dunst xdg-utils
sudo pacman -S --noconfirm python-gobject gtk3

PYTHON_BIN="python"
echo "==> Installing paru (AUR helper)..."
if ! command -v paru >/dev/null 2>&1; then
    sudo pacman -S --needed base-devel git
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si
    cd ..
    rm -rf paru
fi

echo "==> Installing pyenv via paru..."
paru -S --noconfirm pyenv

export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

echo "==> Installing Python 3.12.0 via pyenv..."
pyenv install -s 3.12.0

APP_DIR="$HOME/Downloads/ClipCascade"
ZIP_FILE="/tmp/ClipCascade_Linux.zip"
SERVICE_FILE="$HOME/.config/systemd/user/clipcascade.service"

echo "==> Cleaning old installation..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR"

echo "==> Downloading latest release..."
wget -q --show-progress -O "$ZIP_FILE" "https://github.com/Sathvik-Rao/ClipCascade/releases/latest/download/ClipCascade_Linux.zip"

echo "==> Extracting..."
unzip -q "$ZIP_FILE" -d "$APP_DIR"

# Flatten nested folder if present
if [ -d "$APP_DIR/ClipCascade" ]; then
    echo "==> Flattening folder structure..."
    mv "$APP_DIR/ClipCascade/"* "$APP_DIR/"
    rm -rf "$APP_DIR/ClipCascade"
fi

cd "$APP_DIR"

echo "==> Creating virtual environment..."
echo "==> Installing Python dependencies..."
if [ ! -f "requirements.txt" ]; then
    echo "ERROR: requirements.txt not found."
    exit 1
fi

echo "==> Setting local Python version to 3.12.0..."
pyenv local 3.12.0

echo "==> Creating virtual environment with Python 3.12..."
python -m venv .venv

echo "==> Activating virtual environment..."
source .venv/bin/activate

echo "==> Upgrading pip..."
pip install --upgrade pip

echo "==> Installing Python dependencies from requirements.txt..."
pip install -r requirements.txt

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