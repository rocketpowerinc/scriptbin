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
# Get the list of distro names from WSL (skip header and empty lines)
$distros = wsl.exe --list --online | ForEach-Object {
  $_.Trim()
} | Where-Object { $_ -and ($_ -notmatch '^NAME') } | ForEach-Object {
  ($_ -split '\s+')[0]
}

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
