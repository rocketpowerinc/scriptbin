#*Tags:
# Name: Dotfiles-Gum.ps1
# Shell: pwsh
# Platforms: Windows Docker WSL Server
# Hardware: ROG-Ally ROG-Desktop ROG-Laptop ThinkPad
# Version: Windows10 Windows11
# Architectures: ARM64/AArch64 x86_64
# Framework: Gum
# Type: Bootstrap Appbundle Utility
# Categories: development containerization customization
# Privileges: admin
#*############################################


############ Temp Clone Repository Snippet ############
# Config
$RepoUrl = "https://github.com/rocketpowerinc/dotfiles.git"
$DownloadPath = Join-Path $env:USERPROFILE "Downloads\Temp\dotfiles"

# Make sure parent directory exists
$parentDir = Split-Path -Parent $DownloadPath
if (-not (Test-Path $parentDir)) {
    New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
}

# Remove old copy if it exists
if (Test-Path $DownloadPath) {
    Write-Host "Removing old folder: $DownloadPath"
    Remove-Item -Recurse -Force $DownloadPath
}

# Clone repository
Write-Host "Cloning $RepoUrl into $DownloadPath..."
git clone $RepoUrl $DownloadPath

Write-Host "Done!"