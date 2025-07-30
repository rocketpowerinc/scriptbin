#* This script has to install 7zip because the native Compress-Archive method could not include the hidden .git folder of each repo
#! ADMIN NOT REQUIRED
#! Description: A PowerShell script to backup GitHub repositories and schedule daily backups.
#! It will create a second .ps1 script called RepoBackups-TaskScheduler.ps1 in the user's Bin directory. That task scheduler script will be used to run the backup script daily at 3 AM.
#! New repo's have to be added in the script below twice. Once in the DownloadRepos function and once in the ToggleBackupSchedule function.
#! Then I must enable and disable the task scheduler to update the list of repositories.
#! This Script Goes in $env:USERPROFILE\Bin

# Check if git and 7-zip are installed
function Install-RequiredTools {
  # Check if Git is installed
  if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Output "Installing Git..."
    winget install -e --id Git.Git
  }
  else {
    Write-Output "Git is already installed."
  }

  # Check if 7-Zip is installed
  if (-not (Test-Path "C:\Program Files\7-Zip\7z.exe")) {
    Write-Output "Installing 7-Zip..."
    winget install -e --id 7zip.7zip
  }
  else {
    Write-Output "7-Zip is already installed."
  }
}
Install-RequiredTools

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
  $form.Text = "🚀  Repo Backup Utility"
  $form.Size = New-Object Drawing.Size(500, 300)
  $form.StartPosition = "CenterScreen"
  $form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
  $form.Font = New-Object System.Drawing.Font("Segoe UI Emoji", 10)

  # Title Label
  $titleLabel = New-Object Windows.Forms.Label
  $titleLabel.Text = "Repo Backup Utility"
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
  $buttonDownload.Add_Click({ DownloadRepos -ProgressBar $progressBar -Button $buttonDownload })

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

  # Progress Bar (Spinner)
  $progressBar = New-Object Windows.Forms.ProgressBar
  $progressBar.Location = New-Object Drawing.Point(120, 190)
  $progressBar.Size = New-Object Drawing.Size(250, 20)
  $progressBar.Style = "Continuous"  # Can be "Marquee" for indeterminate Spinner
  $progressBar.Visible = $false
  $progressBar.ForeColor = [System.Drawing.Color]::LimeGreen

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
  $form.Controls.Add($titleLabel)
  $form.Controls.Add($buttonDownload)
  $form.Controls.Add($buttonSchedule)
  $form.Controls.Add($labelStatus)
  $form.Controls.Add($progressBar)

  $form.Add_Shown({ $form.Activate() })
  [void] $form.ShowDialog()
}

# Function to backup repositories
function DownloadRepos {
  param (
    [System.Windows.Forms.ProgressBar]$ProgressBar,
    [System.Windows.Forms.Button]$Button
  )
  try {
    $BackupDir = "$env:USERPROFILE\GitHub-BACKUPS"
    $TempDir = "$env:TEMP\GitHubBackupTemp"
    $Date = Get-Date -Format "yyyy-MM-dd"
    $ZipFile = "$BackupDir\pwr-repo-backup-$Date.zip"

    if (!(Test-Path $BackupDir)) { New-Item -ItemType Directory -Path $BackupDir -Force }
    if (Test-Path $TempDir) { Remove-Item -Path $TempDir -Recurse -Force } # Ensure clean temp dir
    New-Item -ItemType Directory -Path $TempDir -Force

    $Repos = @(
      "https://github.com/rocketpowerinc/windows-greeter.git",
      "https://github.com/rocketpowerinc/mac-greeter.git",
      "https://github.com/rocketpowerinc/linux-greeter.git",
      "https://github.com/rocketpowerinc/appbundles.git",
      "https://github.com/rocketpowerinc/assets.git",
      "https://github.com/rocketpowerinc/scriptbin.git",
      "https://github.com/rocketpowerinc/website.git",
      "https://github.com/rocketpowerinc/dotfiles.git",
      "https://github.com/ChrisTitusTech/mybash.git",
      "https://github.com/rocketpowerinc/go-pwr.git",
      "https://github.com/rocketpowerinc/bluebuild-iso.git",
      "https://github.com/rocketpowerinc/ublue-iso.git",
      "https://github.com/rocketpowerinc/bookmarks.git",
      "https://github.com/rocketpowerinc/gummy.git",
      "https://github.com/ChrisTitusTech/powershell-profile.git"
    )

    # Show and configure progress bar
    $ProgressBar.Visible = $true
    $ProgressBar.Maximum = $Repos.Count
    $ProgressBar.Value = 0
    $Button.Enabled = $false  # Disable button during operation

    foreach ($Repo in $Repos) {
      $RepoName = ($Repo -split '/')[-1] -replace '\.git$', ''
      $RepoPath = "$TempDir\$RepoName"
      git clone $Repo $RepoPath
      $ProgressBar.Value += 1  # Increment progress
      [System.Windows.Forms.Application]::DoEvents()  # Update UI
    }

    # Zip only the newly cloned repositories
    & "C:\Program Files\7-Zip\7z.exe" a -r $ZipFile "$TempDir\*"

    # Clean up temp directory
    Remove-Item -Path $TempDir -Recurse -Force

    # Hide progress bar and re-enable button
    $ProgressBar.Visible = $false
    $Button.Enabled = $true

    [System.Windows.Forms.MessageBox]::Show("Backup Completed: $ZipFile.")
  }
  catch {
    $ProgressBar.Visible = $false
    $Button.Enabled = $true
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
$TempDir = "$env:TEMP\GitHubBackupTemp"
$Date = Get-Date -Format "yyyy-MM-dd"
$ZipFile = "$BackupDir\pwr-repo-backup-$Date.zip"

if (!(Test-Path $BackupDir)) { New-Item -ItemType Directory -Path $BackupDir -Force }
if (Test-Path $TempDir) { Remove-Item -Path $TempDir -Recurse -Force } # Clean temp dir
New-Item -ItemType Directory -Path $TempDir -Force

$Repos = @(
    "https://github.com/rocketpowerinc/windows-greeter.git",
    "https://github.com/rocketpowerinc/mac-greeter.git",
    "https://github.com/rocketpowerinc/linux-greeter.git",
    "https://github.com/rocketpowerinc/appbundles.git",
    "https://github.com/rocketpowerinc/assets.git",
    "https://github.com/rocketpowerinc/scriptbin.git",
    "https://github.com/rocketpowerinc/website.git",
    "https://github.com/rocketpowerinc/dotfiles.git",
    "https://github.com/ChrisTitusTech/mybash.git",
    "https://github.com/rocketpowerinc/go-pwr.git",
    "https://github.com/rocketpowerinc/bluebuild-iso.git",
    "https://github.com/rocketpowerinc/ublue-iso.git",
    "https://github.com/rocketpowerinc/bookmarks.git",
    "https://github.com/rocketpowerinc/gummy.git",
    "https://github.com/ChrisTitusTech/powershell-profile.git"
)

foreach ($Repo in $Repos) {
    $RepoName = ($Repo -split '/')[-1] -replace '\.git$', ''
    $RepoPath = "$TempDir\$RepoName"
    git clone $Repo $RepoPath
}

# Zip only the new cloned repositories
& "C:\Program Files\7-Zip\7z.exe" a -r $ZipFile "$TempDir\*"

# Clean up temp directory
Remove-Item -Path $TempDir -Recurse -Force
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