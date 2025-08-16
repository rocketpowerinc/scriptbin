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
# Define available distros
$distros = @(
    "Debian",
    "Ubuntu",
    "Ubuntu-24.04",
    "archlinux",
    "kali-linux"
)

# Send each distro to gum on its own line
$choice = $distros -join "`n" | gum choose --height 10 --cursor ">"

if ($choice) {
    Write-Host "👉 Press ENTER to begin the installation of $choice." -ForegroundColor Green
    wsl --install -d $choice
}
else {
    Write-Host "No distro selected. Exiting."
}
