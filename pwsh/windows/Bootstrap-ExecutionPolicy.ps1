#*Tags:
# Shell: pwsh
# Platforms: Windows Mac Linux Universal Docker
# Hardware: Steamdeck ROG/Ally/Desktop/Laptop Asus Razor Logitech Nvidia
# Version: Windows10 Windows11
# Architectures: ARM64/AArch64 x86_64
# Framework: Gum
# PackageManagers: winget choco scoop go python
# Type: Bootstrap appbundle
# Categories: utility development virtualization customization productivity backups bookmarks gaming emulation family doomsday Security Privacy
# Privileges: admin user
# Application: tailscale vim github
#*############################################

Write-Host "Setting execution policy to RemoteSigned for the current user  ... Press Enter to continue" -ForegroundColor Green
Read-Host

$ExecutionPolicy = Get-ExecutionPolicy -Scope CurrentUser
if ($ExecutionPolicy -eq "RemoteSigned") {
  Write-Verbose "Execution policy is already set to RemoteSigned for the current user, skipping..." -Verbose
}
else {
  Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
}
# use this line to see if it worked `Get-ExecutionPolicy -List`
