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

# --- prerequisites ---
if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
  Write-Error "WSL is not available on this system."
  exit 1
}
if (-not (Get-Command gum -ErrorAction SilentlyContinue)) {
  Write-Error "gum is not installed. Install it with: winget install charmbracelet.gum"
  exit 1
}

# --- get distro names ---
$distros = & wsl --list --online 2>$null |
Where-Object { $_ -and ($_ -notmatch '^\s*NAME\b') -and ($_ -notmatch '^The following') } |
ForEach-Object {
  # Take everything until two or more spaces (the NAME column)
  ($_ -replace '\s{2,}.*$', '').Trim()
}

if (-not $distros -or $distros.Count -eq 0) {
  Write-Error "No distros found."
  exit 1
}

# --- choose distro ---
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
