#*Tags:
# Name: <script name>.ps1
# Shell: pwsh
# Platforms: Windows Mac Linux Universal Docker WSL
# Hardware: RaspberryPi Steamdeck ROG-Ally ROG-Desktop ROG-Laptop ThinkPad Asus Razor Logitech Nvidia Android
# Version: Windows10 Windows11
# Architectures: ARM64/AArch64 x86_64
# Framework: Gum
# PackageManagers: winget choco scoop go python
# Type: Bootstrap Appbundle Utility
# Categories: development virtualization customization productivity backups bookmarks gaming emulation family doomsday Security Privacy
# Privileges: admin user
# Application: tailscale vim github
# ThirdParty: Titus
#*############################################


############ Temp Clone Repository Snippet ############
# Config
$RepoUrl = "https://github.com/rocketpowerinc/xxx.git"
$DownloadPath = Join-Path $env:USERPROFILE "Downloads\Temp\xxx"

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