@echo off
setlocal

echo ========================================
echo Random File Renamer
echo ========================================
echo.
echo Copy this script into the folder where you want to change all file names.
echo.
echo Current folder:
echo %CD%
echo.
echo This will rename every file in this folder to a random name.
echo This cannot be automatically undone.
echo.
choice /C YN /M "Continue?"
if errorlevel 2 (
  echo.
  echo Cancelled. No files were renamed.
  exit /b 0
)
echo.
echo Renaming files...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
  "$chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';" ^
  "$used = @{};" ^
  "Get-ChildItem -File | ForEach-Object {" ^
  "  do {" ^
  "    $name = -join (1..15 | ForEach-Object { $chars[(Get-Random -Minimum 0 -Maximum $chars.Length)] });" ^
  "  } while ($used.ContainsKey($name) -or (Test-Path -LiteralPath ($name + $_.Extension)));" ^
  "  $used[$name] = $true;" ^
  "  Rename-Item -LiteralPath $_.FullName -NewName ($name + $_.Extension);" ^
  "}"

if errorlevel 1 (
  echo.
  echo Rename failed.
  pause
  exit /b %errorlevel%
)

echo.
echo Done. Files in this folder have been renamed.
pause
