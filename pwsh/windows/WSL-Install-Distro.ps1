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
# Get list of distros, skipping headers
$distros = wsl.exe --list --online | Select-Object -Skip 3 | ForEach-Object {
  ($_ -split '\s{2,}')[0]   # Split on 2+ spaces to get NAME column
} | Where-Object { $_ -ne "" }

# Convert to newline-separated string
$distrosText = $distros -join "`n"

# Use Gum to select multiple distros
$selected = Write-Output $distrosText | gum choose --no-limit

# Install each selected distro
$selected -split "`r?`n" | ForEach-Object {
  $distro = $_.Trim()
  if ($distro) {
    Write-Host "Installing $distro..."
    wsl.exe --install -d $distro
  }
}
