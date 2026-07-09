@echo off
setlocal

set "tempScript=%TEMP%\screen-off-%RANDOM%-%RANDOM%.ps1"

> "%tempScript%" (
  echo Add-Type -TypeDefinition @"
  echo using System;
  echo using System.Runtime.InteropServices;
  echo.
  echo public class MonitorControl {
  echo     [DllImport("user32.dll"^)]
  echo     public static extern int SendMessage(int hWnd, int hMsg, int wParam, int lParam^);
  echo }
  echo "@
  echo.
  echo Write-Host "Turning monitor off in 2 seconds..."
  echo Start-Sleep -Seconds 2
  echo.
  echo [MonitorControl]::SendMessage(-1, 0x0112, 0xF170, 2^) ^| Out-Null
  echo Write-Host "Monitor is now off. Move the mouse or press any key to wake it."
  echo.
  echo Add-Type -AssemblyName System.Windows.Forms
  echo $initial = [System.Windows.Forms.Cursor]::Position
  echo $lastOffCommand = Get-Date
  echo.
  echo while ($true^) {
  echo     Start-Sleep -Milliseconds 200
  echo     $current = [System.Windows.Forms.Cursor]::Position
  echo.
  echo     if ($current.X -ne $initial.X -or $current.Y -ne $initial.Y -or [Console]::KeyAvailable^) {
  echo         [MonitorControl]::SendMessage(-1, 0x0112, 0xF170, -1^) ^| Out-Null
  echo         Write-Host "Monitor waking up."
  echo         break
  echo     }
  echo.
  echo     if (((Get-Date^) - $lastOffCommand^).TotalMinutes -ge 20^) {
  echo         [MonitorControl]::SendMessage(-1, 0x0112, 0xF170, 2^) ^| Out-Null
  echo         $lastOffCommand = Get-Date
  echo     }
  echo }
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%tempScript%"
set "exitCode=%errorlevel%"
del "%tempScript%" >nul 2>nul

exit /b %exitCode%
