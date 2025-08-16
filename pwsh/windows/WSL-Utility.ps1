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
    "wsl --install --no-distribution" `
    "Install Specific Distro (submenu)" `
    "wsl --update" `
    "wsl --status" `
    "wsl --list --verbose" `
    "wsl --list --online" `
    "Set Default Distribution (submenu)" `
    "Unregister Distribution (submenu)" `
    "Exit" `
    --cursor "> " `
    --cursor.foreground 99 `
    --selected.foreground 99 `
    --height 15

  switch ($choice) {
    "wsl --install --no-distribution" {
      Write-Host "Installing WSL without a distribution..." -ForegroundColor Green
      Invoke-Expression $choice
    }
    "Install Specific Distro (submenu)" {
      Show-DistroInstallMenu
    }
    "wsl --update" {
      Write-Host "Updating WSL..." -ForegroundColor Green
      Invoke-Expression $choice
    }
    "wsl --status" {
      Write-Host "Checking WSL status..." -ForegroundColor Green
      Invoke-Expression $choice
    }
    "wsl --list --verbose" {
      Write-Host "Listing installed distributions..." -ForegroundColor Green
      wsl --list --verbose
    }
    "wsl --list --online" {
      Write-Host "Listing available distributions for installation..." -ForegroundColor Green
      wsl --list --online
    }
    "Set Default Distribution (submenu)" {
      Show-SetDefaultMenu
    }
    "Unregister Distribution (submenu)" {
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
    
  $command = gum choose `
    "wsl --install -d Debian" `
    "wsl --install -d Ubuntu" `
    "wsl --install -d Ubuntu-24.04" `
    "wsl --install -d Archlinux" `
    "wsl --install -d Kali-linux" `
    "Back to Main Menu" `
    --cursor "> " `
    --cursor.foreground 99 `
    --selected.foreground 99 `
    --height 10

  if ($command -eq "Back to Main Menu") {
    return
  }
  elseif ($command) {
    Write-Host "Installing distribution..." -ForegroundColor Green
    Invoke-Expression $command
  }
}

function Show-SetDefaultMenu {
  Write-Host ""
  Write-Host "Getting list of installed distributions..." -ForegroundColor Yellow
    
  # Get list of installed distributions
  $installedDistros = (wsl --list --quiet) -split "`r`n" | Where-Object { $_.Trim() -and $_ -notmatch "docker" -and $_ -ne "" }
    
  if ($installedDistros.Count -eq 0) {
    Write-Host "No WSL distributions found. Please install a distribution first." -ForegroundColor Red
    return
  }

  Write-Host "Select a distribution to set as default:" -ForegroundColor Cyan
    
  # Add Back option and build gum command dynamically
  $options = $installedDistros + @("Back to Main Menu")
  $gumArgs = @()
  foreach ($option in $options) {
    $gumArgs += $option.Trim()
  }
  $gumArgs += "--cursor"
  $gumArgs += "> "
  $gumArgs += "--cursor.foreground"
  $gumArgs += "99"
  $gumArgs += "--selected.foreground"
  $gumArgs += "99"
  $gumArgs += "--height"
  $gumArgs += "10"
  
  $selectedDistro = & gum choose @gumArgs

  if ($selectedDistro -eq "Back to Main Menu") {
    return
  }
  elseif ($selectedDistro) {
    Write-Host "Setting $selectedDistro as default distribution..." -ForegroundColor Green
    wsl --set-default $selectedDistro
  }
}

function Show-UnregisterMenu {
  Write-Host ""
  Write-Host "Getting list of installed distributions..." -ForegroundColor Yellow
    
  # Get list of installed distributions
  $installedDistros = (wsl --list --quiet) -split "`r`n" | Where-Object { $_.Trim() -and $_ -notmatch "docker" -and $_ -ne "" }
    
  if ($installedDistros.Count -eq 0) {
    Write-Host "No WSL distributions found." -ForegroundColor Red
    return
  }

  Write-Host "Select a distribution to unregister (WARNING: This will delete all data!):" -ForegroundColor Red
    
  # Add Back option and build gum command dynamically
  $options = $installedDistros + @("Back to Main Menu")
  $gumArgs = @()
  foreach ($option in $options) {
    $gumArgs += $option.Trim()
  }
  $gumArgs += "--cursor"
  $gumArgs += "> "
  $gumArgs += "--cursor.foreground"
  $gumArgs += "99"
  $gumArgs += "--selected.foreground"
  $gumArgs += "99"
  $gumArgs += "--height"
  $gumArgs += "10"
  
  $selectedDistro = & gum choose @gumArgs

  if ($selectedDistro -eq "Back to Main Menu") {
    return
  }
  elseif ($selectedDistro) {
    Write-Host "WARNING: This will permanently delete $selectedDistro and all its data!" -ForegroundColor Red
    $confirm = Read-Host "Type 'YES' to confirm unregistration"
        
    if ($confirm -eq "YES") {
      Write-Host "Unregistering $selectedDistro..." -ForegroundColor Green
      wsl --unregister $selectedDistro
    }
    else {
      Write-Host "Unregistration cancelled." -ForegroundColor Yellow
    }
  }
}

# Start the main menu
Show-WSLMenu
