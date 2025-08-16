#*Tags:
# Name: CTT-WinUtil.ps1
# Shell: pwsh
# Platforms: Windows
# Hardware: ROG-Ally ROG-Desktop ROG-Laptop ThinkPad
# Version: Windows10 Windows11
# Architectures: ARM64/AArch64 x86_64
# Framework: Gum
# PackageManagers: winget choco
# Type: Bootstrap Appbundle Utility
# Categories: development customization
# Privileges: admin
# Third-party: Titus


#*############################################


# Show menu with gum
$choice = & gum choose `
  "Stable Branch (Recommended)" `
  "Dev Branch" `
  "Cancel"

switch ($choice) {
  "Stable Branch (Recommended)" {
    Invoke-RestMethod "https://christitus.com/win" | Invoke-Expression
  }
  "Dev Branch" {
    Invoke-RestMethod "https://christitus.com/windev" | Invoke-Expression
  }
  default {
    Write-Host "Canceled." -ForegroundColor Yellow
  }
}
