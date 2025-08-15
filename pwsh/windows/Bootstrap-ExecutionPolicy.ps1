#*Tags:
# Shell: pwsh
# Platforms: Windows WSL
# Hardware: Desktop Laptop
# Version: Windows10 Windows11
# Architectures: ARM64/AArch64 x86_64
# Type: Bootstrap
# Privileges: admin
#*############################################

Write-Host "Setting execution policy to RemoteSigned for the current user ... Press Enter to continue" -ForegroundColor Green
Read-Host

# Ensure the security module is loaded
Import-Module Microsoft.PowerShell.Security -ErrorAction Stop

try {
  $ExecutionPolicy = Get-ExecutionPolicy -Scope CurrentUser
  if ($ExecutionPolicy -eq "RemoteSigned") {
    Write-Verbose "Execution policy is already set to RemoteSigned for the current user, skipping..." -Verbose
  }
  else {
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
    Write-Host "Execution policy updated." -ForegroundColor Green
  }
}
catch {
  Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nFinal Execution Policy settings:" -ForegroundColor Cyan
Get-ExecutionPolicy -List
