& {
    $profile = Get-ChildItem "$env:APPDATA\Mozilla\Firefox\Profiles" |
        Where-Object { $_.Name -like "*.default-release" } |
        Select-Object -First 1

    $db = Join-Path $profile.FullName "places.sqlite"

    & "sqlite3" $db @"
SELECT p.url
FROM moz_bookmarks b
JOIN moz_places p ON b.fk = p.id
WHERE b.parent = (
  SELECT id FROM moz_bookmarks WHERE title='Download'
);
"@
} | Set-Content -Path ".\download.txt"