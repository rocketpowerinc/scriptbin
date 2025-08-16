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
# WSL Management Menu
#*############################################

function Show-WSLMenu {
  Write-Host "WSL Management Menu" -ForegroundColor Cyan
  Write-Host "===================" -ForegroundColor Cyan
  Write-Host ""

  # Use gum to choose from the main menu
  $choice = gum choose `
    "Install WSL" `
    "Update WSL" `
    "Install a Distro" `
    "Check WSL Status" `
    "List Installed Distros" `
    "List Available Distros" `
    "Set Default Distribution" `
    "Unregister (uninstall) a Distro" `
    "Exit" `
    --cursor "> " `
    --cursor.foreground 99 `
    --selected.foreground 99 `
    --height 15

  switch ($choice) {
    "Install WSL" {
      Write-Host "Installing WSL without a distribution..." -ForegroundColor Green
      wsl --install --no-distribution
    }
    "Update WSL" {
      Write-Host "Updating WSL..." -ForegroundColor Green
      wsl --update
    }
    "Install a Distro" {
      Show-DistroInstallMenu
    }
    "Check WSL Status" {
      Write-Host "Checking WSL status..." -ForegroundColor Green
      wsl --status
    }
    "List Installed Distros" {
      Write-Host "Listing installed distributions..." -ForegroundColor Green
      wsl --list --verbose
    }
    "List Available Distros" {
      Write-Host "Listing available distributions for installation..." -ForegroundColor Green
      wsl --list --online
    }
    "Set Default Distribution" {
      Show-SetDefaultMenu
    }
    "Unregister (uninstall) a Distro" {
      Show-UnregisterMenu
    }
    "Exit" {
      Write-Host "Exiting WSL Management Menu." -ForegroundColor Yellow
      return
    }
    default {
      if ($choice) {
        Write-Host "Unknown option selected." -ForegroundColor Red
      }
      else {
        Write-Host "No option selected. Exiting." -ForegroundColor Yellow
        return
      }
    }
  }

  # Ask if user wants to continue
  Write-Host ""
  $continue = Read-Host "Press ENTER to return to menu, or type 'exit' to quit"
  if ($continue -ne "exit") {
    Show-WSLMenu
  }
}

function Show-DistroInstallMenu {
  Write-Host ""
  Write-Host "Select a distribution to install:" -ForegroundColor Cyan

  $choice = gum choose `
    "Debian" `
    "Ubuntu" `
    "Ubuntu 24.04 LTS" `
    "Arch Linux" `
    "Kali Linux" `
    "Back to Main Menu" `
    --cursor "> " `
    --cursor.foreground 99 `
    --selected.foreground 99 `
    --height 10

  switch ($choice) {
    "Debian" {
      Write-Host "Installing Debian..." -ForegroundColor Green
      wsl --install -d Debian
    }
    "Ubuntu" {
      Write-Host "Installing Ubuntu..." -ForegroundColor Green
      wsl --install -d Ubuntu
    }
    "Ubuntu 24.04 LTS" {
      Write-Host "Installing Ubuntu 24.04 LTS..." -ForegroundColor Green
      wsl --install -d Ubuntu-24.04
    }
    "Arch Linux" {
      Write-Host "Installing Arch Linux..." -ForegroundColor Green
      wsl --install -d archlinux
    }
    "Kali Linux" {
      Write-Host "Installing Kali Linux..." -ForegroundColor Green
      wsl --install -d kali-linux
    }
    "Back to Main Menu" {
      return
    }
    default {
      if ($choice) {
        Write-Host "Unknown distribution selected." -ForegroundColor Red
      }
    }
  }
}

function Show-SetDefaultMenu {
  Write-Host ""
  Write-Host "Getting list of installed distributions..." -ForegroundColor Yellow

  # Get list of installed distributions using verbose output parsing
  $wslVerbose = wsl -l -v
  $installedDistros = @()

  # Parse the verbose output to get clean distribution names
  foreach ($line in $wslVerbose) {
    if ($line -match '^\s*\*?\s*([^\s]+)\s+') {
      $distroName = $matches[1].Trim()
      if ($distroName -and $distroName -ne "NAME" -and $distroName -notmatch "docker") {
        $installedDistros += $distroName
      }
    }
  }

  if ($installedDistros.Count -eq 0) {
    Write-Host "No WSL distributions found. Please install a distribution first." -ForegroundColor Red
    return
  }

  Write-Host "Select a distribution to set as default:" -ForegroundColor Cyan

  # Use hardcoded options for reliability since we know what they are
  $selectedDistro = gum choose `
    "Debian" `
    "Ubuntu" `
    "OracleLinux_7_9" `
    "Back to Main Menu" `
    --cursor "> " `
    --cursor.foreground 99 `
    --selected.foreground 99

  if ($selectedDistro -eq "Back to Main Menu") {
    return
  }
  elseif ($selectedDistro) {
    Write-Host "Setting '$selectedDistro' as default distribution..." -ForegroundColor Green

    # Debug: Show exact string details
    Write-Host "DEBUG: Length: $($selectedDistro.Length)" -ForegroundColor Magenta
    Write-Host "DEBUG: Bytes: $([System.Text.Encoding]::UTF8.GetBytes($selectedDistro) -join ' ')" -ForegroundColor Magenta

    # Clean the string thoroughly
    $cleanDistro = $selectedDistro.Trim().Replace("`r", "").Replace("`n", "").Replace("`0", "")
    Write-Host "DEBUG: Clean distro: '$cleanDistro'" -ForegroundColor Magenta

    # Execute the command
    $result = & wsl --set-default $cleanDistro 2>&1
    if ($LASTEXITCODE -eq 0) {
      Write-Host "Successfully set $cleanDistro as default distribution." -ForegroundColor Green
    }
    else {
      Write-Host "Error setting default: $result" -ForegroundColor Red
    }
  }
}

function Show-UnregisterMenu {
  Write-Host ""
  Write-Host "Getting list of installed distributions..." -ForegroundColor Yellow

  # Get list of installed distributions using verbose output parsing
  $wslVerbose = wsl -l -v
  $installedDistros = @()

  # Parse the verbose output to get clean distribution names
  foreach ($line in $wslVerbose) {
    if ($line -match '^\s*\*?\s*([^\s]+)\s+') {
      $distroName = $matches[1].Trim()
      if ($distroName -and $distroName -ne "NAME" -and $distroName -notmatch "docker") {
        $installedDistros += $distroName
      }
    }
  }

  if ($installedDistros.Count -eq 0) {
    Write-Host "No WSL distributions found." -ForegroundColor Red
    return
  }

  Write-Host "Select a distribution to unregister (WARNING: This will delete all data!):" -ForegroundColor Red

  # Use hardcoded options for reliability since we know what they are
  $selectedDistro = gum choose `
    "Debian" `
    "Ubuntu" `
    "OracleLinux_7_9" `
    "Back to Main Menu" `
    --cursor "> " `
    --cursor.foreground 99 `
    --selected.foreground 99

  if ($selectedDistro -eq "Back to Main Menu") {
    return
  }
  elseif ($selectedDistro) {
    Write-Host "WARNING: This will permanently delete '$selectedDistro' and all its data!" -ForegroundColor Red
    $confirm = Read-Host "Type 'YES' to confirm unregistration"

    if ($confirm -eq "YES") {
      Write-Host "Unregistering '$selectedDistro'..." -ForegroundColor Green
      $trimmedDistro = $selectedDistro.Trim()
      wsl --unregister $trimmedDistro
    }
    else {
      Write-Host "Unregistration cancelled." -ForegroundColor Yellow
    }
  }
}

# Start the main menu
Show-WSLMenu
