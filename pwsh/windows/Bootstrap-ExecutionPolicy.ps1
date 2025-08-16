#*Tags:
# Name: Bootstrap-ExecutionPolicy.ps1
# Shell: pwsh
# Platforms: Windows WSL
# Hardware: ROG-Ally ROG-Desktop ROG-Laptop ThinkPad
# Version: Windows10 Windows11
# Architectures: ARM64/AArch64 x86_64
# Type: Bootstrap
# Privileges: admin bootstrap
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