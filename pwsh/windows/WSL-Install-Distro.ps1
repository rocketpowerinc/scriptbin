#*Tags:
# Type: Gum
# Shell: pwsh
# Platforms: Windows Docker
# Hardware: Desktop Laptop
# Version: Windows11
# Architectures: x86_64
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

# --- get distro list (try --quiet first, then fallback to parsing) ---
$distros = @()
try {
  $q = & wsl --list --online --quiet 2>$null
  if ($q) { $distros = $q }
}
catch { }

if (-not $distros) {
  $raw = & wsl --list --online 2>$null
  $distros = $raw |
  Where-Object { $_ -and ($_ -notmatch '^\s*NAME\b') -and ($_ -notmatch 'The following') } |
  ForEach-Object { ($_ -split '\s+')[0] } |
  Where-Object { $_ }
}

if (-not $distros -or $distros.Count -eq 0) {
  Write-Error "Couldn't retrieve the online distro list."
  exit 1
}

# --- choose distro with gum ---
$choice = $distros | & gum choose --height 15 --cursor ">" --header "Select a WSL distro to install"
if (-not $choice) {
  Write-Host "No selection made. Exiting."
  exit 0
}

# Optional confirmation
if (-not (& gum confirm "Install '$choice' with WSL now?")) {
  Write-Host "Cancelled."
  exit 0
}

# --- install ---
Write-Host "Running: wsl --install -d $choice" -ForegroundColor Cyan
& wsl --install -d $choice
$code = $LASTEXITCODE

if ($code -eq 0) {
  Write-Host "✅ '$choice' installation command executed."
}
else {
  Write-Error "wsl exited with code $code."
}
