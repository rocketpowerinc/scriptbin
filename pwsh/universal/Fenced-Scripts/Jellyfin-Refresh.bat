@echo off
setlocal

set "ApiKey=ebf5131d790a459794c06b6ab59e56bd"
set "JellyfinUrl=http://192.168.1.53:8096"
set "StatusFile=%TEMP%\jellyfin-refresh-status-%RANDOM%-%RANDOM%.tmp"

echo ========================================
echo Jellyfin Library Refresh
echo ========================================
echo Server: %JellyfinUrl%
echo Started: %date% %time%
echo.
echo Sending refresh request to Jellyfin...
echo.

curl.exe -sS -o nul -w "HTTP_STATUS=%%{http_code}" -X POST "%JellyfinUrl%/Library/Refresh" ^
  -H "X-MediaBrowser-Token: %ApiKey%" > "%StatusFile%"

set "CurlExitCode=%errorlevel%"

if not "%CurlExitCode%"=="0" (
  del "%StatusFile%" >nul 2>nul
  echo Failed to contact Jellyfin.
  echo curl exit code: %CurlExitCode%
  echo.
  echo Check that Jellyfin is running and reachable at %JellyfinUrl%.
  echo.
  pause
  exit /b %CurlExitCode%
)

for /f "tokens=2 delims==" %%A in ('type "%StatusFile%" 2^>nul') do set "HttpStatus=%%A"
del "%StatusFile%" >nul 2>nul

if "%HttpStatus%"=="" (
  echo Jellyfin answered, but the script could not read the HTTP status.
  echo.
  pause
  exit /b 1
)

if "%HttpStatus%"=="204" (
  echo Success: Jellyfin accepted the library refresh request.
  echo The scan will continue in the background inside Jellyfin.
) else if "%HttpStatus%"=="200" (
  echo Success: Jellyfin accepted the library refresh request.
  echo The scan will continue in the background inside Jellyfin.
) else if "%HttpStatus%"=="401" (
  echo Jellyfin rejected the request: the API key was not accepted.
  echo HTTP status: %HttpStatus%
  echo.
  pause
  exit /b 1
) else (
  echo Jellyfin returned an unexpected response.
  echo HTTP status: %HttpStatus%
  echo.
  pause
  exit /b 1
)

echo.
echo Finished: %date% %time%
echo.
pause
