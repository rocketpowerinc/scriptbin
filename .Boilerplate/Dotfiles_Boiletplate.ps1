# Define app name
$app = "xxxxxxxx"

# Common Sources
$source      = Join-Path $env:USERPROFILE "Downloads\Temp\dotfiles\$app"
#Common Destinations
$destination = Join-Path $env:USERPROFILE "Docker\docker-compose\$app"

Write-Host "Copying files from:" -ForegroundColor Cyan
Write-Host "  $source" -ForegroundColor Yellow
Write-Host "to:" -ForegroundColor Cyan
Write-Host "  $destination" -ForegroundColor Yellow

# Make sure the source exists
if (-not (Test-Path $source)) {
    Write-Error "Source path does not exist: $source"
    exit 1
}

# Ensure destination directory exists
if (-not (Test-Path $destination)) {
    New-Item -ItemType Directory -Path $destination -Force | Out-Null
    Write-Host "Created destination directory: $destination" -ForegroundColor Green
}

# Copy contents (recursive, overwrite)
Copy-Item -Path (Join-Path $source '*') -Destination $destination -Recurse -Force

Write-Host "✅ Copy complete!" -ForegroundColor Green
