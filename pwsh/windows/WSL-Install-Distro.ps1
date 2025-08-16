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

# Install-WSLWithGum.ps1
# Lets you pick a WSL distro via gum, then runs: wsl --install -d <distro>

# --- prerequisites ---
if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
  Write-Error "WSL is not available on this system."
  exit 1
}
if (-not (Get-Command gum -ErrorAction SilentlyContinue)) {
  Write-Error "gum is not installed. Install it with: winget install charmbracelet.gum"
  exit 1
}

# --- get distro list ---
$raw = & wsl --list --online 2>$null |
Where-Object { $_ -and ($_ -notmatch '^\s*NAME\b') -and ($_ -notmatch '^The following') }

$distros = @()
foreach ($line in $raw) {
  # Capture the actual name (first column) and friendly name (rest)
  if ($line -match '^(?<name>\S+)\s+(?<friendly>.+)$') {
    $distros += [PSCustomObject]@{
      Name     = $matches['name']
      Friendly = $matches['friendly']
    }
  }
}

if (-not $distros -or $distros.Count -eq 0) {
  Write-Error "Couldn't retrieve the online distro list."
  exit 1
}

# --- choose distro with gum (show friendly names) ---
$choiceFriendly = $distros.Friendly | & gum choose --height 15 --cursor ">" --header "Select a WSL distro to install"
if (-not $choiceFriendly) {
  Write-Host "No selection made. Exiting."
  exit 0
}

# Map friendly name back to actual distro name
$choice = ($distros | Where-Object { $_.Friendly -eq $choiceFriendly }).Name

# Optional confirmation
if (-not (& gum confirm "Install '$choiceFriendly' with WSL now?")) {
  Write-Host "Cancelled."
  exit 0
}

# --- install ---
Write-Host "Running: wsl --install -d $choice" -ForegroundColor Cyan
& wsl --install -d $choice
$code = $LASTEXITCODE

if ($code -eq 0) {
  Write-Host "✅ '$choiceFriendly' installation command executed."
}
else {
  Write-Error "wsl exited with code $code."
}
