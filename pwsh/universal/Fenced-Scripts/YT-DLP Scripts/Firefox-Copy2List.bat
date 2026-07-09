@echo off
setlocal

set "profileRoot=%APPDATA%\Mozilla\Firefox\Profiles"

for /f "delims=" %%P in ('dir /b /ad "%profileRoot%\*.default-release" 2^>nul') do (
  set "profile=%profileRoot%\%%P"
  goto :FoundProfile
)

echo Firefox default-release profile not found.
exit /b 1

:FoundProfile
set "db=%profile%\places.sqlite"
set "sqlFile=%TEMP%\firefox-download-bookmarks-%RANDOM%-%RANDOM%.sql"

> "%sqlFile%" (
  echo WITH RECURSIVE download_folders(id^) AS ^(
  echo   SELECT id
  echo   FROM moz_bookmarks
  echo   WHERE id = ^(
  echo     SELECT id
  echo     FROM moz_bookmarks
  echo     WHERE title = 'Download' AND type = 2
  echo     ORDER BY id
  echo     LIMIT 1
  echo   ^)
  echo.
  echo   UNION ALL
  echo.
  echo   SELECT b.id
  echo   FROM moz_bookmarks b
  echo   JOIN download_folders f ON b.parent = f.id
  echo   WHERE b.type = 2
  echo ^)
  echo SELECT p.url
  echo FROM moz_bookmarks b
  echo JOIN download_folders f ON b.parent = f.id
  echo JOIN moz_places p ON b.fk = p.id
  echo WHERE b.type = 1;
)

sqlite3 "%db%" < "%sqlFile%" > ".\download.txt"
set "sqliteExit=%errorlevel%"
del "%sqlFile%" >nul 2>nul

if not "%sqliteExit%"=="0" (
  echo Failed to export Firefox Download bookmarks. Make sure sqlite3 is installed and Firefox is closed if the database is locked.
  exit /b %sqliteExit%
)

echo Firefox Download bookmarks exported to download.txt.
