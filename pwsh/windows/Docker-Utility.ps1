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
  "Install Docker Desktop (docker engine and compose included)" `
  "Install LazyDocker" `
  "Clone Docker Repo" `
  "Deploy Containers" `
  "Exit" `
  --cursor "> " `
  --cursor.foreground 99 `
  --selected.foreground 99 `
  --height 15

switch ($choice) {
  "Install Docker Desktop (docker engine and compose included)" {
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

      # Get all subdirectories in the source
      $sourceFolders = Get-ChildItem -Path $SourceDockerCompose -Directory

      foreach ($folder in $sourceFolders) {
        $destinationFolder = Join-Path $DockerComposeDestination $folder.Name

        # Create destination folder if it doesn't exist
        if (-not (Test-Path $destinationFolder)) {
          New-Item -ItemType Directory -Path $destinationFolder -Force | Out-Null
          Write-Host "Created folder: $destinationFolder" -ForegroundColor Green
        }

        # Copy all contents from source folder to destination, overwriting existing files but preserving others
        Write-Host "Copying contents from $($folder.Name)..." -ForegroundColor Cyan
        Copy-Item -Path "$($folder.FullName)\*" -Destination $destinationFolder -Recurse -Force
        Write-Host "Copied: $($folder.Name) contents to $destinationFolder" -ForegroundColor Green
      }

      Write-Host "Docker-compose files moved successfully (existing files preserved, matching files overwritten)" -ForegroundColor Green
    }
    else {
      Write-Host "Warning: docker-compose folder not found in cloned repository" -ForegroundColor Yellow
    }

    # Clean up temporary download folder
    Write-Host "Cleaning up temporary folder: $DownloadPath" -ForegroundColor Cyan
    if (Test-Path $DownloadPath) {
      Remove-Item -Recurse -Force $DownloadPath
      Write-Host "Temporary folder removed successfully" -ForegroundColor Green
    }
  }

  "Deploy Containers" {
    Write-Host ">>> Selecting Docker Compose file..." -ForegroundColor Cyan
    $DockerComposeDir = Join-Path $env:USERPROFILE "Docker\docker-compose"

    if (-not (Test-Path $DockerComposeDir)) {
      Write-Host "Error: Docker compose directory not found at $DockerComposeDir" -ForegroundColor Red
      Write-Host "Please run 'Clone Docker Repo' first to set up the directory structure." -ForegroundColor Yellow
      return
    }

    # Use gum file to select a docker-compose.yml file
    $selectedFile = gum file $DockerComposeDir --file

    if (-not $selectedFile) {
      Write-Host "No file selected. Exiting..." -ForegroundColor Yellow
      return
    }

    # Check if the selected file is a docker-compose file
    $fileName = Split-Path -Leaf $selectedFile
    if ($fileName -notmatch "docker-compose.*\.ya?ml$") {
      Write-Host "Warning: Selected file '$fileName' doesn't appear to be a docker-compose file." -ForegroundColor Yellow
      $confirm = Read-Host "Do you want to continue anyway? (y/N)"
      if ($confirm -notmatch "^[yY]") {
        Write-Host "Operation cancelled." -ForegroundColor Yellow
        return
      }
    }

    # Get the directory containing the selected file
    $composeDir = Split-Path -Parent $selectedFile

    Write-Host "Deploying containers from: $selectedFile" -ForegroundColor Cyan
    Write-Host "Changing directory to: $composeDir" -ForegroundColor Cyan

    # Change to the directory and run docker compose
    Push-Location $composeDir
    try {
      docker compose up -d
      Write-Host "Containers deployed successfully!" -ForegroundColor Green
    }
    catch {
      Write-Host "Error deploying containers: $_" -ForegroundColor Red
    }
    finally {
      Pop-Location
    }
  }



  "Exit" {
    Write-Host "Goodbye!" -ForegroundColor Yellow
    exit 0
  }
}
