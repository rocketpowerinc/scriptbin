#* Native Compress-Archive not 7zip but does not include hidden .git folder of each repo which takes alot of space anyway
#! ADMIN NOT REQUIRED
#! Description: A PowerShell script to backup GitHub repositories and schedule daily backups.
#! It will create a second .ps1 script called RepoBackups-TaskScheduler.ps1 in the user's Bin directory. That task scheduler script will be used to run the backup script daily at 3 AM.
#! New repo's have to be added in the scipt below twice. Once in the DownloadRepos function and once in the ToggleBackupSchedule function.


# Check if git is installed
$gitInstalled = Get-Command git -ErrorAction SilentlyContinue
if ($null -eq $gitInstalled) {
  Write-Output "Git is not installed. Installing Git..."
  winget install -e --id Git.Git
}
else {
  Write-Output "Git is already installed."
}

# Windows Form GUI
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function CheckTaskStatus {
  $TaskName = "GitHubBackup"
  $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
  if ($task -and $task.State -eq "Ready") {
    return "Enabled"
  }
  else {
    return "Disabled"
  }
}

function Show-BackupForm {
  $form = New-Object Windows.Forms.Form
  $form.Text = "🚀 GitHub Backup Utility"
  $form.Size = New-Object Drawing.Size(500, 300)
  $form.StartPosition = "CenterScreen"
  $form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
  $form.Font = New-Object System.Drawing.Font("Segoe UI Emoji", 10)

  # Title Label
  $titleLabel = New-Object Windows.Forms.Label
  $titleLabel.Text = "GitHub Backup Tool"
  $titleLabel.AutoSize = $true
  $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI Emoji", 14, [System.Drawing.FontStyle]::Bold)
  $titleLabel.ForeColor = [System.Drawing.Color]::White
  $titleLabel.Location = New-Object Drawing.Point(150, 10)

  # Backup Button
  $buttonDownload = New-Object Windows.Forms.Button
  $buttonDownload.Text = "📥 Backup Repositories"
  $buttonDownload.Size = New-Object Drawing.Size(250, 50)
  $buttonDownload.Location = New-Object Drawing.Point(120, 60)
  $buttonDownload.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
  $buttonDownload.ForeColor = [System.Drawing.Color]::White
  $buttonDownload.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
  $buttonDownload.Add_Click({ DownloadRepos })

  # Schedule Button
  $buttonSchedule = New-Object Windows.Forms.Button
  $buttonSchedule.Size = New-Object Drawing.Size(250, 50)
  $buttonSchedule.Location = New-Object Drawing.Point(120, 130)
  $buttonSchedule.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
  $buttonSchedule.ForeColor = [System.Drawing.Color]::White
  $buttonSchedule.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
  $buttonSchedule.Add_Click({ ToggleBackupSchedule })

  # Task Status Label
  $labelStatus = New-Object Windows.Forms.Label
  $labelStatus.Location = New-Object Drawing.Point(120, 200)
  $labelStatus.Size = New-Object Drawing.Size(250, 30)
  $labelStatus.Font = New-Object System.Drawing.Font("Segoe UI Emoji", 12, [System.Drawing.FontStyle]::Bold)

  function Update-Status {
    $status = CheckTaskStatus
    if ($status -eq "Enabled") {
      $labelStatus.Text = "✅ Task Scheduler: ENABLED"
      $labelStatus.ForeColor = [System.Drawing.Color]::LimeGreen
      $buttonSchedule.Text = "🚫 Disable Daily Backup"
    }
    else {
      $labelStatus.Text = "❌ Task Scheduler: DISABLED"
      $labelStatus.ForeColor = [System.Drawing.Color]::Red
      $buttonSchedule.Text = "🕒 Enable Daily Backup"
    }
  }


  Update-Status

  # Add elements to form
  $form.Controls.Add($titleLabel)   # Add the title label here
  $form.Controls.Add($buttonDownload)
  $form.Controls.Add($buttonSchedule)
  $form.Controls.Add($labelStatus)

  $form.Add_Shown({ $form.Activate() })
  [void] $form.ShowDialog()
}

# Function to backup repositories
function DownloadRepos {
  try {
    $BackupDir = "$env:USERPROFILE\GitHub-BACKUPS"
    $Date = Get-Date -Format "yyyy-MM-dd"
    $ZipFile = "$BackupDir\pwr-repo-backup-$Date.zip"

    if (!(Test-Path $BackupDir)) { New-Item -ItemType Directory -Path $BackupDir -Force }

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
      }
      else {
        git clone $Repo $RepoPath
      }
    }

    # Exclude previous .zip files from being included in the new backup
    Compress-Archive -Path (Get-ChildItem -Path $BackupDir -Directory) -DestinationPath $ZipFile -Force

    foreach ($Repo in $Repos) {
      $RepoName = ($Repo -split '/')[-1] -replace '\.git$', ''
      $RepoPath = "$BackupDir\$RepoName"
      if (Test-Path $RepoPath) { Remove-Item -Path $RepoPath -Recurse -Force }
    }

    [System.Windows.Forms.MessageBox]::Show("Backup Completed: $ZipFile.")
  }
  catch {
    [System.Windows.Forms.MessageBox]::Show("An error occurred: $_")
  }
}

# Function to toggle daily backup schedule
function ToggleBackupSchedule {
  $BackupScript = "$env:USERPROFILE\Bin\RepoBackups-TaskScheduler.ps1"
  $TaskName = "GitHubBackup"

  if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    # Task exists, remove it (Disable)
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    [System.Windows.Forms.MessageBox]::Show("Daily Backup Disabled.")
  }
  else {
    # Task does not exist, create it (Enable)
    $ScriptContent = @'
$BackupDir = "$env:USERPROFILE\GitHub-BACKUPS"
$Date = Get-Date -Format "yyyy-MM-dd"
$ZipFile = "$BackupDir\pwr-repo-backup-$Date.zip"

if (!(Test-Path $BackupDir)) { New-Item -ItemType Directory -Path $BackupDir -Force }

$Repos = @(
    "https://github.com/rocketpowerinc/linux-greeter.git",
    "https://github.com/rocketpowerinc/appbundles.git",
    "https://github.com/rocketpowerinc/assets",
    "https://github.com/rocketpowerinc/scriptbin.git"
)

foreach ($Repo in $Repos) {
    $RepoName = ($Repo -split '/')[-1] -replace '\.git$', ''
    $RepoPath = "$BackupDir\$RepoName"
    if (Test-Path $RepoPath) { git -C $RepoPath pull }
    else { git clone $Repo $RepoPath }
}

# Exclude previous .zip files from being included in the new backup
Compress-Archive -Path (Get-ChildItem -Path $BackupDir -Directory) -DestinationPath $ZipFile -Force

foreach ($Repo in $Repos) {
    $RepoName = ($Repo -split '/')[-1] -replace '\.git$', ''
    $RepoPath = "$BackupDir\$RepoName"
    if (Test-Path $RepoPath) { Remove-Item -Path $RepoPath -Recurse -Force }
}
'@

    if (!(Test-Path $env:USERPROFILE\Bin)) { New-Item -ItemType Directory -Path $env:USERPROFILE\Bin -Force }
    Set-Content -Path $BackupScript -Value $ScriptContent

    $Action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-ExecutionPolicy Bypass -File `"$BackupScript`""
    $Trigger = New-ScheduledTaskTrigger -Daily -At 3am
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    $Principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive

    Register-ScheduledTask -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal -TaskName $TaskName -Description "GitHub Repositories Backup"

    [System.Windows.Forms.MessageBox]::Show("Daily Backup Scheduled at 3 AM.")
  }

  # Update status label
  Update-Status

  # Open Task Scheduler after enabling/disabling the task
  Start-Process "taskschd.msc"
}

# Show the form
Show-BackupForm
