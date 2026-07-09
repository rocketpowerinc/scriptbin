@echo off
setlocal

set "ApiKey=ebf5131d790a459794c06b6ab59e56bd"

curl.exe -sS -X POST "http://192.168.1.53:8096/Library/Refresh" ^
  -H "X-MediaBrowser-Token: %ApiKey%"

if errorlevel 1 (
  echo Jellyfin library refresh request failed.
  exit /b %errorlevel%
)

echo Jellyfin library refresh requested.
