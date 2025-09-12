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
$boilerplateDir = Join-Path $DownloadPath ".boilerplate"

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

if (Test-Path $boilerplateDir) {
  Write-Host "Removing .boilerplate directory..." -ForegroundColor Yellow
  Remove-Item -Recurse -Force $boilerplateDir
}


Write-Host "Temp Dotfiles folder cloned/refreshed successfully!" -ForegroundColor Green
Write-Host "Please Select a pwr-path script to place your selected dotfile configs" -ForegroundColor Magenta
Write-Host "Press Enter to continue..." -ForegroundColor Blue
[void][System.Console]::ReadLine()

# Main loop for file selection and execution
do {
  # Clear screen completely and reset cursor to top
  Clear-Host

  # Find all .ps1 and .sh script files recursively, excluding hidden/unwanted directories
  $scriptFiles = @()
  $scriptFiles += Get-ChildItem -Path $DownloadPath -Recurse -Filter "*.ps1" | Where-Object { 
    $_.FullName -notmatch '[\\/]\.vscode[\\/]' -and 
    $_.FullName -notmatch '[\\/]\.git[\\/]' -and 
    $_.FullName -notmatch '[\\/]\.boilerplate[\\/]' -and
    $_.FullName -notmatch '[\\/]pwsh[\\/]profile\.ps1$'
  } | ForEach-Object { $_.FullName }
  $scriptFiles += Get-ChildItem -Path $DownloadPath -Recurse -Filter "*.sh" | Where-Object { 
    $_.FullName -notmatch '[\\/]\.vscode[\\/]' -and 
    $_.FullName -notmatch '[\\/]\.git[\\/]' -and 
    $_.FullName -notmatch '[\\/]\.boilerplate[\\/]'
  } | ForEach-Object { $_.FullName }

  if ($scriptFiles.Count -eq 0) {
    Write-Host "No .ps1 or .sh script files found in $DownloadPath" -ForegroundColor Yellow
    break
  }

  Write-Host "Found $($scriptFiles.Count) script files (.ps1 and .sh)" -ForegroundColor Green

  # Create relative paths for display and sort alphabetically
  $displayFiles = $scriptFiles | ForEach-Object { 
    $_.Replace($DownloadPath, "").TrimStart('\') 
  } | Sort-Object

  # Use gum choose to select from the list
  $selectedDisplay = ($displayFiles -join "`n") | gum choose --height 20

  if (-not $selectedDisplay) {
    Write-Host "No file selected. Exiting..." -ForegroundColor Yellow
    break
  }

  # Get the full path of the selected file
  $selectedFile = Join-Path $DownloadPath $selectedDisplay

  # Check if the selected file is a PowerShell or bash script
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
  elseif ($fileExtension -eq ".sh") {
    if (Get-Command bash -ErrorAction SilentlyContinue) {
      Write-Host "Running Bash script: $selectedFile" -ForegroundColor Cyan
      bash $selectedFile
      Write-Host "Script execution completed." -ForegroundColor Green
    }
    elseif (Get-Command wsl -ErrorAction SilentlyContinue) {
      Write-Host "Running Bash script via WSL: $selectedFile" -ForegroundColor Cyan
      wsl bash $selectedFile
      Write-Host "Script execution completed." -ForegroundColor Green
    }
    else {
      Write-Host "Bash not found. Cannot execute .sh files automatically." -ForegroundColor Yellow
    }
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