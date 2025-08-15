#*Tags:
# Shell: pwsh
# Platforms: Windows WSL
# Hardware: Desktop Laptop
# Version: Windows10 Windows11
# Architectures: ARM64/AArch64 x86_64
# Type: Bootstrap
# Privileges: admin
#*############################################

# If not running with Bypass, restart script with Bypass
if ($ExecutionContext.SessionState.LanguageMode -ne 'FullLanguage') {
  Write-Host "Restarting with ExecutionPolicy Bypass..."
  powershell -NoProfile -ExecutionPolicy Bypass -File "`"$PSCommandPath`""
  exit
}

Write-Host "Setting execution policy to RemoteSigned for the current user ... Press Enter to continue" -ForegroundColor Green
Read-Host

Import-Module Microsoft.PowerShell.Security -ErrorAction Stop

$ExecutionPolicy = Get-ExecutionPolicy -Scope CurrentUser
if ($ExecutionPolicy -eq "RemoteSigned") {
  Write-Verbose "Execution policy is already set to RemoteSigned for the current user, skipping..." -Verbose
}
else {
  Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
}

Write-Host "`nFinal Execution Policy settings:" -ForegroundColor Cyan
Get-ExecutionPolicy -List
