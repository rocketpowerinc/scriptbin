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


# Clone Dotfiles Repo as soon as script is Launched
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

# Clean up unwanted files and directories
$vscodeDir = Join-Path $DownloadPath ".vscode"
$readmeFile = Join-Path $DownloadPath "readme.md"
$gitDir = Join-Path $DownloadPath ".git"

if (Test-Path $vscodeDir) {
  Write-Host "Removing .vscode directory..." -ForegroundColor Yellow
  Remove-Item -Recurse -Force $vscodeDir
}

if (Test-Path $readmeFile) {
  Write-Host "Removing readme.md file..." -ForegroundColor Yellow
  Remove-Item -Force $readmeFile
}

if (Test-Path $gitDir) {
  Write-Host "Removing .git directory..." -ForegroundColor Yellow
  Remove-Item -Recurse -Force $gitDir
}

Clear-Host
Write-Host "Temp Dotfiles folder cloned/refreshed successfully!" -ForegroundColor Green
Write-Host "Please Select a pwr-path script to place your selected dotfile configs" -ForegroundColor Magenta

# Main loop for file selection and execution
do {
  # Use gum file to select a file
  $selectedFile = gum file $DownloadPath

  if (-not $selectedFile) {
    Write-Host "No file selected. Exiting..." -ForegroundColor Yellow
    break
  }

  # Check if the selected file is a PowerShell script
  $fileExtension = [System.IO.Path]::GetExtension($selectedFile)
  if ($fileExtension -eq ".ps1") {
    Write-Host "Running PowerShell script: $selectedFile" -ForegroundColor Cyan
    pwsh -File $selectedFile
    Write-Host "Script execution completed." -ForegroundColor Green
    Write-Host ""
    $runAnother = Read-Host "Do you want to run another script? (Y/n)"
    if ($runAnother -match "^[nN]") {
      break
    }
  }
  else {
    Write-Host "Selected file: $selectedFile" -ForegroundColor Green
    Write-Host "This is not a PowerShell script (.ps1), so it won't be executed automatically." -ForegroundColor Yellow
    Write-Host ""
    $runAnother = Read-Host "Do you want to select another file? (Y/n)"
    if ($runAnother -match "^[nN]") {
      break
    }
  }
} while ($true)