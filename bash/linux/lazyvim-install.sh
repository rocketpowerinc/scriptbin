#!/usr/bin/env bash

#*Tags:
# Name: lazyvim-install.sh
# Shell: bash
# Platforms: Linux Server WSL
# Hardware: RaspberryPi Steamdeck ROG-Ally ROG-Desktop ROG-Laptop ThinkPad Android
# Distros: Ubuntu Debian Fedora Arch Opensuse
# Architectures: ARM64/AArch64 x86_64
# DisplayServers: Wayland x11
# PackageManagers: apt dnf pacman zypper
# DesktopEnvironments: Gnome kde hyprland xfce
# Type: Bootstrap
# Categories: productivity
# Privileges: admin
# Application: vim


#* Function to update package database and install dependencies based on the distro
install_dependencies() {
  if [ -f /etc/debian_version ]; then
    # Debian-based
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y git fzf ripgrep fd-find

    #todo Install Neovim from source (because debian is to out of date as of Feb 2025)
    sudo apt install ninja-build gettext libtool libtool-bin autoconf automake cmake g++ pkg-config unzip curl doxygen
    git clone https://github.com/neovim/neovim.git
    cd neovim
    git checkout stable
    make CMAKE_BUILD_TYPE=Release
    sudo make install


    #lazygit
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit -D -t /usr/local/bin/
  elif [ -f /etc/fedora-release ]; then
    # Fedora-based
    sudo dnf update -y
    sudo dnf install -y neovim git lazygit fzf ripgrep fd-find
  elif [ -f /etc/arch-release ]; then
    # Arch-based
    sudo pacman -Syu --noconfirm
    sudo pacman -S --noconfirm neovim git lazygit fzf ripgrep fd
  elif [ -f /etc/SuSE-release ] || [ -f /etc/os-release ] && grep -q "openSUSE" /etc/os-release; then
    # openSUSE-based
    sudo zypper refresh
    sudo zypper install -y neovim git lazygit fzf ripgrep fd
  else
    echo -e "\e[31mUnsupported Linux distribution.\e[0m"
    exit 1
  fi
}

# Backup old Neovim configuration
backup_old_config() {
  mv -f ~/.config/nvim{,.bak} 2>/dev/null
  mv -f ~/.local/share/nvim{,.bak} 2>/dev/null
  mv -f ~/.local/state/nvim{,.bak} 2>/dev/null
  mv -f ~/.cache/nvim{,.bak} 2>/dev/null
}

# Clone LazyVim repository
setup_neovim() {
  [ -d ~/.config/nvim ] && rm -rf ~/.config/nvim
  git clone https://github.com/LazyVim/starter ~/.config/nvim
  rm -rf ~/.config/nvim/.git
}

# Start Neovim to complete the setup
start_neovim() {
  nvim
}

# Main script execution
install_dependencies
backup_old_config
setup_neovim
start_neovim
