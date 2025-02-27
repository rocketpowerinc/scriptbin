# Variables
$BackupDir = "$env:USERPROFILE\GitHub-pwr-BACKUPS"
$Date = Get-Date -Format "yyyy-MM-dd"
$ZipFile = "$BackupDir\pwr-repo-backup-$Date.zip"
$BackupScript = "$env:USERPROFILE\Bin\Run-GitHub-Backups.ps1"
$TaskName = "GitHubBackup"
$ScriptContent = @'
$BackupDir = "$env:USERPROFILE\GitHub-pwr-BACKUPS"
$Date = Get-Date -Format "yyyy-MM-dd"
$ZipFile = "$BackupDir\pwr-repo-backup-$Date.zip"

if (!(Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir -Force
}

$Repos = @(
    "https://github.com/rocketpowerinc/linux-greeter.git",
    "https://github.com/rocketpowerinc/appbundles.git",
    "https://github.com/rocketpowerinc/assets",
    "https://github.com/rocketpowerinc/scriptbin.git"
)

foreach ($Repo in $Repos) {
    $RepoName = ($Repo -split '/')[-1] -replace '\.git$', ''
    $RepoPath = "$BackupDir\$RepoName"

    if (Test-Path $RepoPath) {
        git -C $RepoPath pull
    } else {
        git clone $Repo $RepoPath
    }
}

Compress-Archive -Path "$BackupDir\*" -DestinationPath $ZipFile -Force

foreach ($Repo in $Repos) {
    $RepoName = ($Repo -split '/')[-1] -replace '\.git$', ''
    $RepoPath = "$BackupDir\$RepoName"

    if (Test-Path $RepoPath) {
        Remove-Item -Path $RepoPath -Recurse -Force
    }
}
'@

# Create Backup Script
if (!(Test-Path $env:USERPROFILE\Bin)) {
    New-Item -ItemType Directory -Path $env:USERPROFILE\Bin -Force
}
Set-Content -Path $BackupScript -Value $ScriptContent

# Check if the task already exists and remove it
if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

# Create Scheduled Task
$Action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-ExecutionPolicy Bypass -File `"$BackupScript`""
$Trigger = New-ScheduledTaskTrigger -Daily -At 3am
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
$Principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive

Register-ScheduledTask -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal -TaskName $TaskName -Description "GitHub Repositories Backup"
