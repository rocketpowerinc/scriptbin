#*Tags:
# Shell: pwsh
# Platforms: Windows Mac Linux Universal
# Version: Windows10 Windows11
# Architectures: ARM64/AArch64 x86_64
# PackageManagers: winget choco scoop go python
# Categories: utility development customization productivity Backups
# Privileges: admin user


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