# Function to check for admin privileges and relaunch with elevated permissions if necessary
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "GitHub Backup Manager"
$form.Size = New-Object System.Drawing.Size(400, 250)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)

# Download Repos Button
$btnDownload = New-Object System.Windows.Forms.Button
$btnDownload.Location = New-Object System.Drawing.Point(100, 30)
$btnDownload.Size = New-Object System.Drawing.Size(200, 40)
$btnDownload.Text = "Download Repos"
$btnDownload.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
$btnDownload.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($btnDownload)

# Toggle Backup Button
$btnToggleBackup = New-Object System.Windows.Forms.Button
$btnToggleBackup.Location = New-Object System.Drawing.Point(100, 80)
$btnToggleBackup.Size = New-Object System.Drawing.Size(200, 40)
$btnToggleBackup.Text = "Enable Daily Backup"
$btnToggleBackup.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
$btnToggleBackup.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($btnToggleBackup)

# Status Label
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Location = New-Object System.Drawing.Point(150, 140)
$statusLabel.Size = New-Object System.Drawing.Size(200, 20)
$statusLabel.Text = "Backup: OFF"
$statusLabel.ForeColor = [System.Drawing.Color]::Red
$form.Controls.Add($statusLabel)

$BackupScriptPath = "$env:APPDATA\github_backup.ps1"
$TaskName = "GitHubBackup"
$BackupEnabled = $null -ne (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue)


Function UpdateStatus {
    if ($BackupEnabled) {
        $statusLabel.Text = "Backup: ON"
        $statusLabel.ForeColor = [System.Drawing.Color]::Green
        $btnToggleBackup.Text = "Disable Daily Backup"
    }
    else {
        $statusLabel.Text = "Backup: OFF"
        $statusLabel.ForeColor = [System.Drawing.Color]::Red
        $btnToggleBackup.Text = "Enable Daily Backup"
    }
}

# Updated DownloadRepos Function
Function DownloadRepos {
    try {
        $BackupDir = "$env:USERPROFILE\GitHub-pwr\Backups"
        $Date = Get-Date -Format "yyyy-MM-dd"
        $ZipFile = "$BackupDir\pwr-repo-backup-$Date.zip"

        if (!(Test-Path $BackupDir)) {
            New-Item -ItemType Directory -Path $BackupDir -Force
        }

        # Define your list of repository URLs
        $Repos = @(
            "https://github.com/rocketpowerinc/linux-greeter.git"
            "https://github.com/rocketpowerinc/appbundles.git"
            "https://github.com/rocketpowerinc/assets"
            "https://github.com/rocketpowerinc/scriptbin.git"
            # Continue adding as needed
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

        Compress-Archive -Path "$BackupDir\*" -DestinationPath $ZipFile -Force

        # Delete the original repository directories after zipping
        foreach ($Repo in $Repos) {
            $RepoName = ($Repo -split '/')[-1] -replace '\.git$', ''
            $RepoPath = "$BackupDir\$RepoName"

            if (Test-Path $RepoPath) {
                Remove-Item -Path $RepoPath -Recurse -Force
            }
        }

        [System.Windows.Forms.MessageBox]::Show("Backup Completed: $ZipFile. Original files have been deleted.")
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("An error occurred: $_")
    }
}

# Updated ToggleBackup Function
Function ToggleBackup {
    if ($BackupEnabled) {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        $BackupEnabled = $false
    }
    else {
        # Prepare the backup script content
        $BackupScriptContent = @"
try {
    `$BackupDir = "`"$BackupDir`""
    `$Date = Get-Date -Format "`"yyyy-MM-dd`""
    `$ZipFile = "`"$BackupDir\pwr-repo-backup-`$Date.zip`""

    if (!(Test-Path `$BackupDir)) {
        New-Item -ItemType Directory -Path `$BackupDir -Force
    }

    # Define your list of repository URLs
    `$Repos = @(
        `"https://github.com/rocketpowerinc/linux-greeter.git`"
        # Add more repositories here
    )

    foreach (`$Repo in `$Repos) {
        `$RepoName = (`$Repo -split '/')[-1] -replace '\\.git$',''
        `$RepoPath = "`"$BackupDir\`$RepoName`""

        if (Test-Path `$RepoPath) {
            git -C `$RepoPath pull
        } else {
            git clone `$Repo `$RepoPath
        }
    }

    Compress-Archive -Path "`"$BackupDir\*`"" -DestinationPath "`"$ZipFile`"" -Force

    # Delete the original repository directories after zipping
    foreach (`$Repo in `$Repos) {
        `$RepoName = (`$Repo -split '/')[-1] -replace '\\.git$',''
        `$RepoPath = "`"$BackupDir\`$RepoName`""

        if (Test-Path `$RepoPath) {
            Remove-Item -Path `$RepoPath -Recurse -Force
        }
    }
} catch {
    # Handle errors if necessary
}
"@

        # Save the backup script
        Set-Content -Path $BackupScriptPath -Value $BackupScriptContent

        # Create the scheduled task
        $Action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-ExecutionPolicy Bypass -File `"$BackupScriptPath`""
        $Trigger = New-ScheduledTaskTrigger -Daily -At 3am
        Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -User "$env:USERNAME" -RunLevel Highest -Force
        $BackupEnabled = $true
    }
    UpdateStatus

    # Open the Task Scheduler to confirm the task was created
    Start-Process "taskschd.msc"
}

# Event handlers for buttons
$btnDownload.Add_Click({ DownloadRepos })
$btnToggleBackup.Add_Click({ ToggleBackup })
UpdateStatus

# Show the form
$form.ShowDialog()
