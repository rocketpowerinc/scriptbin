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
# Get list of distro NAMES - hardcoded from WSL output
Write-Host "Available WSL distributions:"
$distros = @(
  "AlmaLinux-8",
  "AlmaLinux-9", 
  "AlmaLinux-Kitten-10",
  "AlmaLinux-10",
  "Debian",
  "FedoraLinux-42",
  "SUSE-Linux-Enterprise-15-SP6",
  "SUSE-Linux-Enterprise-15-SP7", 
  "Ubuntu",
  "Ubuntu-24.04",
  "archlinux",
  "kali-linux",
  "openSUSE-Tumbleweed",
  "openSUSE-Leap-15.6",
  "Ubuntu-18.04",
  "Ubuntu-20.04", 
  "Ubuntu-22.04",
  "OracleLinux_7_9",
  "OracleLinux_8_10",
  "OracleLinux_9_5"
)

# Verify WSL is available and show current list
try {
  Write-Host "`nCurrent WSL online distributions:"
  wsl.exe --list --online
  Write-Host "`n"
}
catch {
  Write-Host "Warning: Could not retrieve current WSL list. Using built-in list." -ForegroundColor Yellow
}

Write-Host "Using distribution list for selection:"
$distros | ForEach-Object { Write-Host "  $_" }

# Convert to newline-separated string for Gum
$distrosText = $distros -join "`n"

# Use Gum to select multiple distros in a vertical list (height 25)
Write-Host "Please select distributions to install (use Space to select, Enter to confirm):" -ForegroundColor Yellow
try {
    $selected = Write-Output $distrosText | gum choose --no-limit --height 25
    Write-Host "Selected: $selected" -ForegroundColor Green
} catch {
    Write-Host "Gum selection failed or was cancelled." -ForegroundColor Red
    exit 1
}

if (-not $selected -or $selected.Trim() -eq "") {
    Write-Host "No distributions selected." -ForegroundColor Yellow
    exit 0
}

Write-Host "Proceeding with installation of selected distributions..." -ForegroundColor Cyan

# Install each selected distro
$selectedDistros = $selected -split "`r?`n" | Where-Object { $_.Trim() }
Write-Host "Will install $($selectedDistros.Count) distributions:" -ForegroundColor Green
$selectedDistros | ForEach-Object { Write-Host "  - $_" -ForegroundColor Green }

foreach ($distro in $selectedDistros) {
    $distro = $distro.Trim()
    if ($distro) {
        Write-Host "`nInstalling $distro..." -ForegroundColor Cyan
        try {
            $result = wsl.exe --install -d $distro
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Successfully installed $distro" -ForegroundColor Green
            } else {
                Write-Host "Failed to install $distro (exit code: $LASTEXITCODE)" -ForegroundColor Red
                Write-Host "Output: $result" -ForegroundColor Red
            }
        } catch {
            Write-Host "Error installing $distro`: $_" -ForegroundColor Red
        }
    }
}
