#!/usr/bin/env bash
set -euo pipefail

#*Tags:
# Name: clipcascade-install-nixos.sh
# Shell: bash
# Platforms: Linux
# Hardware: RaspberryPi Steamdeck ROG-Ally ROG-Desktop ROG-Laptop ThinkPad
# Distros: NixOS
# Architectures: ARM64/AArch64 x86_64
# DisplayServers: Wayland
# PackageManagers: nix python
# DesktopEnvironments: Gnome
# Type: Bootstrap
# Categories: productivity
# Privileges: admin
# Application: ClipCascade

cleanup() {
    echo -e "\n\n!!! CRASH DETECTED !!!"
    echo "Check the error message above."
    read -p "Press enter to exit..."
}
trap cleanup ERR

echo "==> ClipCascade NixOS installer starting..."

# Install Dependencies if they don't exist
nix-env -q xclip >/dev/null 2>&1 || nix-env -iA nixos.xclip && \
nix-env -q wl-clipboard >/dev/null 2>&1 || nix-env -iA nixos.wl-clipboard

# Requirements for the installer environment
nix-shell -p \
    python3 \
    python3Packages.virtualenv \
    python3Packages.pip \
    python3Packages.tkinter \
    wget \
    unzip \
    --run "$(cat << 'EOF'
set -e

APP_DIR="$HOME/.local/share/ClipCascade"
SYSTEMD_DIR="$HOME/.config/systemd/user"
ZIP_FILE="/tmp/ClipCascade_Linux.zip"

mkdir -p "$APP_DIR" "$SYSTEMD_DIR"

echo "==> Downloading latest release..."
wget -q --show-progress -O "$ZIP_FILE" "https://github.com/Sathvik-Rao/ClipCascade/releases/latest/download/ClipCascade_Linux.zip"

echo "==> Extracting files..."
unzip -q -o "$ZIP_FILE" -d "$APP_DIR"

# Find the actual code directory (handles nested folders in ZIP)
REQ_PATH=$(find "$APP_DIR" -name "requirements.txt" -print -quit)
if [ -z "$REQ_PATH" ]; then
    echo "Error: Could not find requirements.txt!"
    exit 1
fi

REAL_ROOT=$(dirname "$REQ_PATH")
cd "$REAL_ROOT"

echo "==> Setting up Python Virtualenv..."
python3 -m venv .venv --system-site-packages
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

echo "==> Creating NixOS-compatible systemd service..."

# Create a wrapper script that loads the Nix environment
WRAPPER_SCRIPT="$REAL_ROOT/start-clipcascade.sh"
cat > "$WRAPPER_SCRIPT" <<'WRAPPER_EOF'
#!/usr/bin/env nix-shell
#!nix-shell -i bash -p python3 python3Packages.tkinter stdenv.cc.cc.lib ffmpeg xorg.libX11 xorg.libXcursor xorg.libXrandr xorg.libXinerama xorg.libXi xorg.libXfixes wayland libxkbcommon tk

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# Ensure LD_LIBRARY_PATH includes necessary libraries
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$(nix-build --no-out-link '<nixpkgs>' -A stdenv.cc.cc.lib)/lib"

exec "$SCRIPT_DIR/.venv/bin/python" "$SCRIPT_DIR/main.py"
WRAPPER_EOF

chmod +x "$WRAPPER_SCRIPT"

# Create systemd service that uses the wrapper
cat > "$SYSTEMD_DIR/clipcascade.service" <<INNER_EOF
[Unit]
Description=ClipCascade Clipboard Sync
After=graphical-session.target

[Service]
Type=simple
WorkingDirectory=$REAL_ROOT
ExecStart=$WRAPPER_SCRIPT
Restart=always
RestartSec=5
Environment="PATH=/run/current-system/sw/bin:/etc/profiles/per-user/%u/bin:$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin"
Environment="DISPLAY=:0"

[Install]
WantedBy=default.target
INNER_EOF

echo "==> Activating service..."
systemctl --user daemon-reload
systemctl --user enable clipcascade.service
systemctl --user start clipcascade.service

echo "------------------------------------------------"
echo "==> SUCCESS!"
echo "ClipCascade is now running as a background user service."
echo ""
echo "Useful commands:"
echo "  View logs:    journalctl --user -u clipcascade -f"
echo "  Stop service: systemctl --user stop clipcascade"
echo "  Start service: systemctl --user start clipcascade"
echo "  Check status: systemctl --user status clipcascade"
echo "------------------------------------------------"
EOF
)"