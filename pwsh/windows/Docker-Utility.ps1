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

# Show menu
$choice = gum choose `
  "Install Docker and Docker Compose" `
  "Install Docker Desktop" `
  "Install LazyDocker" `
  "Clone Docker Repo" `
  "Exit" `
  --cursor "> " `
  --cursor.foreground 99 `
  --selected.foreground 99 `
  --height 15

switch ($choice) {
  "Install Docker and Docker Compose" {
    Write-Host ">>> Installing Docker Desktop (includes Docker & Docker Compose)..." -ForegroundColor Cyan
    $dockerInstaller = "$env:TEMP\DockerDesktopInstaller.exe"
    Invoke-WebRequest -Uri "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe" -OutFile $dockerInstaller
    Start-Process -FilePath $dockerInstaller -Wait
    Write-Host "Docker Desktop installation finished. Please log out and log in again if required." -ForegroundColor Green
  }

  "Install Docker Desktop" {
    Write-Host ">>> Installing Docker Desktop via Winget..." -ForegroundColor Cyan
    winget install -e --id Docker.DockerDesktop
    Write-Host "Docker Desktop installation via Winget completed." -ForegroundColor Green
  }

  "Install LazyDocker" {
    Write-Host ">>> Installing LazyDocker..." -ForegroundColor Cyan
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
      scoop install lazydocker
      Add-Content -Path $PROFILE -Value "Set-Alias lzd lazydocker"
    }
    Write-Host "LazyDocker installation completed." -ForegroundColor Green
  }

  "Clone Docker Repo" {
    Write-Host ">>> Cloning Docker repo..." -ForegroundColor Cyan
    # Config
    $RepoUrl = "https://github.com/rocketpowerinc/docker.git"
    $DownloadPath = Join-Path $env:USERPROFILE "Downloads\Temp\Docker"

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

    Write-Host "Repo cloned successfully to $DownloadPath" -ForegroundColor Green

    # Create Docker directories in user profile
    $DockerComposeDestination = Join-Path $env:USERPROFILE "Docker\docker-compose"

    Write-Host "Creating Docker directories..." -ForegroundColor Cyan
    if (-not (Test-Path $DockerComposeDestination)) {
      New-Item -ItemType Directory -Path $DockerComposeDestination -Force | Out-Null
    }    # Move docker-compose files from temp to permanent location
    $SourceDockerCompose = Join-Path $DownloadPath "docker-compose"
    if (Test-Path $SourceDockerCompose) {
      Write-Host "Moving docker-compose files to $DockerComposeDestination..." -ForegroundColor Cyan

      #* Overwrite existing docker-compose files - no data should get deleted or overwritten
      if (Test-Path $DockerComposeDestination) {
        Remove-Item -Path "$DockerComposeDestination\*" -Recurse -Force
      }
      Copy-Item -Path "$SourceDockerCompose\*" -Destination $DockerComposeDestination -Recurse -Force
      Write-Host "Docker-compose files moved successfully" -ForegroundColor Green
    }
    else {
      Write-Host "Warning: docker-compose folder not found in cloned repository" -ForegroundColor Yellow
    }
  }



  "Exit" {
    Write-Host "Goodbye!" -ForegroundColor Yellow
    exit 0
  }
}
