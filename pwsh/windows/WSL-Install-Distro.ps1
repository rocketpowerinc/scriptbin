#*Tags:
# Shell: pwsh
# Platforms: Windows Docker WSL
# Hardware: Desktop Laptop
# Version: Windows11
# Architectures: x86_64
# Framework: Gum
# Type: Bootstrap
# Categories: virtualization
# Privileges: admin

#*############################################

# Use gum to choose a WSL distro and capture the selected command
$command = gum choose `
    "wsl --install -d Debian" `
    "wsl --install -d Ubuntu" `
    "wsl --install -d Ubuntu-24.04" `
    "wsl --install -d Archlinux" `
    "wsl --install -d Kali-linux" `
    --cursor "> " `
    --cursor.foreground 99 `
    --selected.foreground 99

# Run the selected command if the user made a choice
if ($command) {
    Invoke-Expression $command
}
