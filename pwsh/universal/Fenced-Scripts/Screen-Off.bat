@echo off
setlocal
title Keep Monitor Off

set "tempScript=%TEMP%\screen-off-%RANDOM%-%RANDOM%.ps1"

> "%tempScript%" (
  echo Add-Type -TypeDefinition @"
  echo using System;
  echo using System.Runtime.InteropServices;
  echo public static class MonitorControl {
  echo     [DllImport("user32.dll"^)]
  echo     public static extern IntPtr SendMessage(IntPtr hWnd, uint hMsg, IntPtr wParam, IntPtr lParam^);
  echo     [DllImport("user32.dll"^)]
  echo     public static extern short GetAsyncKeyState(int vKey^);
  echo }
  echo "@
  echo.
  echo function Turn-MonitorOff {
  echo     [MonitorControl]::SendMessage([IntPtr]0xffff, 0x0112, [IntPtr]0xF170, [IntPtr]2^) ^| Out-Null
  echo }
  echo function Turn-MonitorOn {
  echo     [MonitorControl]::SendMessage([IntPtr]0xffff, 0x0112, [IntPtr]0xF170, [IntPtr](-1^)^) ^| Out-Null
  echo }
  echo Add-Type -AssemblyName System.Windows.Forms
  echo.
  echo Clear-Host
  echo Write-Host "KEEP MONITOR OFF" -ForegroundColor Cyan
  echo Write-Host "This window will send an OFF command every 5 minutes."
  echo Write-Host "Mouse movement will trigger another OFF command immediately."
  echo Write-Host "Keyboard input remains enabled."
  echo Write-Host "Press Ctrl+C anywhere to stop and wake the monitor." -ForegroundColor Yellow
  echo Write-Host ""
  echo.
  echo for ($seconds = 2; $seconds -ge 1; $seconds--^) {
  echo     Write-Host ("`rTurning monitor off in {0,2} seconds... " -f $seconds^) -NoNewline
  echo     Start-Sleep -Seconds 1
  echo }
  echo Write-Host "`rTurning monitor off now...          "
  echo.
  echo Turn-MonitorOff
  echo [Console]::TreatControlCAsInput = $true
  echo $lastPosition = [System.Windows.Forms.Cursor]::Position
  echo $lastOffCommand = Get-Date
  echo $next = $lastOffCommand.AddMinutes(5^)
  echo Write-Host ("[{0}] OFF command sent. Backup check: {1}" -f $lastOffCommand.ToString('HH:mm:ss'^), $next.ToString('HH:mm:ss'^)^)
  echo.
  echo while ($true^) {
  echo     Start-Sleep -Milliseconds 100
  echo.
  echo     $controlDown = ([MonitorControl]::GetAsyncKeyState(0x11^) -band 0x8000^) -ne 0
  echo     $cDown = ([MonitorControl]::GetAsyncKeyState(0x43^) -band 0x8000^) -ne 0
  echo     if ($controlDown -and $cDown^) {
  echo         [Console]::TreatControlCAsInput = $false
  echo         Turn-MonitorOn
  echo         Write-Host "Stop command received. Monitor enabled." -ForegroundColor Green
  echo         break
  echo     }
  echo.
  echo     $currentPosition = [System.Windows.Forms.Cursor]::Position
  echo.
  echo     if ($currentPosition.X -ne $lastPosition.X -or $currentPosition.Y -ne $lastPosition.Y^) {
  echo         Turn-MonitorOff
  echo         $lastPosition = $currentPosition
  echo         $lastOffCommand = Get-Date
  echo         continue
  echo     }
  echo.
  echo     if (((Get-Date^) - $lastOffCommand^).TotalMinutes -ge 5^) {
  echo         Turn-MonitorOff
  echo         $lastOffCommand = Get-Date
  echo         $next = $lastOffCommand.AddMinutes(5^)
  echo         Write-Host ("[{0}] Backup OFF command sent. Next: {1}" -f $lastOffCommand.ToString('HH:mm:ss'^), $next.ToString('HH:mm:ss'^)^)
  echo     }
  echo }
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%tempScript%"
set "exitCode=%errorlevel%"
del "%tempScript%" >nul 2>nul

exit /b %exitCode%
