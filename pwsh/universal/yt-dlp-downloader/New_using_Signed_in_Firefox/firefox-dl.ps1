<#
.SYNOPSIS
Exports Firefox bookmark URLs from the Download folder to download.txt.

.DESCRIPTION
Finds the first Firefox profile ending in .default-release and reads its
places.sqlite bookmark database. URLs saved directly inside the Firefox
bookmark folder named Download, including URLs in nested subfolders at any
depth, are written to .\download.txt in the current working directory.

.REQUIREMENTS
The sqlite3 command-line tool must be installed and available on PATH.
#>
& {
    $profile = Get-ChildItem "$env:APPDATA\Mozilla\Firefox\Profiles" |
    Where-Object { $_.Name -like "*.default-release" } |
    Select-Object -First 1

    $db = Join-Path $profile.FullName "places.sqlite"

    & "sqlite3" $db @"
WITH RECURSIVE download_folders(id) AS (
  SELECT id
  FROM moz_bookmarks
  WHERE id = (
    SELECT id
    FROM moz_bookmarks
    WHERE title = 'Download' AND type = 2
    ORDER BY id
    LIMIT 1
  )

  UNION ALL

  SELECT b.id
  FROM moz_bookmarks b
  JOIN download_folders f ON b.parent = f.id
  WHERE b.type = 2
)
SELECT p.url
FROM moz_bookmarks b
JOIN download_folders f ON b.parent = f.id
JOIN moz_places p ON b.fk = p.id
WHERE b.type = 1;
"@
} | Set-Content -Path ".\download.txt"