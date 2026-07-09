# Recursively detect and optionally remove Mark of the Web (MOTW)

$extensions = @("*.ps1","*.psm1","*.bat","*.cmd","*.vbs","*.js","*.py","*.exe")

Write-Host "Scanning recursively for files with Mark of the Web..." -ForegroundColor Cyan

$motwFiles = @()

foreach ($ext in $extensions) {
    Get-ChildItem -Path . -Filter $ext -Recurse | ForEach-Object {
        $zone = Get-Item $_.FullName -Stream Zone.Identifier -ErrorAction SilentlyContinue
        if ($zone) {
            $motwFiles += $_
        }
    }
}

if ($motwFiles.Count -eq 0) {
    Write-Host "No files in this directory or subdirectories have Mark of the Web." -ForegroundColor Green
    return
}

Write-Host "`nFiles with Mark of the Web:" -ForegroundColor Yellow
$motwFiles | ForEach-Object { Write-Host " - $($_.FullName)" }

$choice = Read-Host "`nDo you want to remove MOTW from these files? (Y/N)"

if ($choice -match '^[Yy]$') {
    foreach ($file in $motwFiles) {
        try {
            Unblock-File -Path $file.FullName
            Write-Host "Unblocked: $($file.FullName)" -ForegroundColor Green
        } catch {
            Write-Host "Failed to unblock: $($file.FullName) - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "No changes made." -ForegroundColor Cyan
}
