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

# Get the list of distro names from WSL
$distros = wsl.exe --list --online | Select-Object -Skip 1 | ForEach-Object {
    ($_ -split '\s+')[0]
}

# Convert to newline-separated string
$distrosText = $distros -join "`n"

# Use Gum to select multiple distros
$selected = Write-Output $distrosText | gum choose --no-limit

# Install each selected distro using -d flag
$selected.Split("`n") | ForEach-Object {
    if ($_ -ne "") {
        Write-Host "Installing $_..."
        wsl.exe --install -d $_
    }
}
