@echo off
setlocal DisableDelayedExpansion

set "scriptRoot=%~dp0"
set "inputFile=%scriptRoot%download.txt"

for /f %%I in ('powershell.exe -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH-mm"') do set "dateStamp=%%I"
set "dateFolder=%scriptRoot%%dateStamp%"
set "failedFile=%dateFolder%\00-failed.txt"

if not exist "%dateFolder%" mkdir "%dateFolder%"

if not exist "%inputFile%" (
  echo download.txt not found!
  exit /b 1
)

if exist "%failedFile%" del "%failedFile%"
set "hadFailures=0"

for /f "usebackq delims=" %%U in ("%inputFile%") do call :ProcessUrl "%%U"

if "%hadFailures%"=="0" (
  > "%failedFile%" echo Success all links downloaded
)

echo All downloads complete!
exit /b 0

:ProcessUrl
setlocal DisableDelayedExpansion
set "url=%~1"
if "%url%"=="" exit /b 0
set "YT_DLP_URL=%url%"
set "YT_DLP_DATE_FOLDER=%dateFolder%"
set "YT_DLP_FAILED_FILE=%failedFile%"

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
  "$url = $env:YT_DLP_URL;" ^
  "$dateFolder = $env:YT_DLP_DATE_FOLDER;" ^
  "Write-Host ('Processing: ' + $url);" ^
  "if ($url -match 'youtube\.com|youtu\.be') {" ^
  "  Write-Host 'YouTube detected - using <=480p + Firefox cookies';" ^
  "  & yt-dlp --no-playlist --cookies-from-browser firefox -f 'bv*[height<=480][ext=mp4]+ba[ext=m4a]/b[ext=mp4]/best' -o (Join-Path $dateFolder '%%(title).100s.%%(ext)s') $url;" ^
  "} elseif ($url -match 'instagram\.com') {" ^
  "  Write-Host 'Instagram detected - using Firefox cookies';" ^
  "  & yt-dlp --cookies-from-browser firefox --user-agent 'Mozilla/5.0' -o (Join-Path $dateFolder '%%(title).100s.%%(ext)s') $url;" ^
  "} else {" ^
  "  Write-Host 'Other site detected - using default download';" ^
  "  & yt-dlp -o (Join-Path $dateFolder '%%(title).100s.%%(ext)s') $url;" ^
  "}" ^
  "exit $LASTEXITCODE"

if errorlevel 1 (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Write-Host ('Failed: ' + $env:YT_DLP_URL); Add-Content -LiteralPath $env:YT_DLP_FAILED_FILE -Value $env:YT_DLP_URL"
  endlocal & set "hadFailures=1"
) else (
  endlocal
)

echo --------------------------------------
exit /b 0
