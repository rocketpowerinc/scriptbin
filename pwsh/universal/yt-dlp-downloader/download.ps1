# ============================================
# Batch Video Downloader (yt-dlp PowerShell)
#
# - Reads URLs from download.txt (one per line)
# - Downloads all videos using yt-dlp
# - Uses smart <=480p MP4 format for YouTube links
# - Saves downloads into a folder named with today's date + time (YYYY-MM-DD_HH-mm)
# - Logs failures to 00-failed.txt inside the download folder
# - Writes success message if no failures occur
# - Limits filename length to prevent Windows errors
# - Skips empty lines automatically
# ============================================

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$inputFile = Join-Path $scriptRoot "download.txt"

# Create today's date + time folder
$dateFolder = Join-Path $scriptRoot (Get-Date -Format "yyyy-MM-dd_HH-mm")

if (!(Test-Path $dateFolder)) {
  New-Item -ItemType Directory -Path $dateFolder | Out-Null
}

# Failed file now lives inside the new folder
$failedFile = Join-Path $dateFolder "00-failed.txt"

# Track failures
$failedList = @()

# Check if input file exists
if (!(Test-Path $inputFile)) {
  Write-Host "❌ download.txt not found!"
  exit
}

# Process each URL
Get-Content $inputFile | ForEach-Object {

  $url = $_.Trim()
  if ([string]::IsNullOrWhiteSpace($url)) { return }

  Write-Host "⬇️ Processing: $url"

  $command = {
    yt-dlp -o "$dateFolder/%(title).100s.%(ext)s" "$url"
  }

  if ($url -match "youtube\.com|youtu\.be") {
    Write-Host "🎥 YouTube detected — using smart <=480p format"

    $command = {
      yt-dlp --no-playlist `
        -f "bv*[height<=480][ext=mp4]+ba[ext=m4a]/b[ext=mp4]/best" `
        -o "$dateFolder/%(title).100s.%(ext)s" `
        "$url"
    }
  }
  else {
    Write-Host "🌐 Other site detected — using default download"
  }

  try {
    & $command
    if ($LASTEXITCODE -ne 0) {
      throw "Download failed"
    }
  }
  catch {
    Write-Host "❌ Failed: $url"
    $failedList += $url
  }

  Write-Host "--------------------------------------"
}

# Write failure log inside the date folder
if ($failedList.Count -gt 0) {
  $failedList | Out-File -FilePath $failedFile -Encoding utf8
}
else {
  "Success all links downloaded" | Out-File -FilePath $failedFile -Encoding utf8
}

Write-Host "✅ All downloads complete!"