Add-Type -AssemblyName System.Windows.Forms

# Function to create and display the form
function Show-BackupForm {
    $form = New-Object Windows.Forms.Form
    $form.Text = "GitHub Backup Utility"
    $form.Size = New-Object Drawing.Size(400,200)
    $form.StartPosition = "CenterScreen"
    $form.BackColor = [System.Drawing.Color]::FromArgb(45,45,48) # Dark mode background color

    # Download Repos button
    $buttonDownload = New-Object Windows.Forms.Button
    $buttonDownload.Text = "Backup Repositories"
    $buttonDownload.Size = New-Object Drawing.Size(150,50)
    $buttonDownload.Location = New-Object Drawing.Point(50,50)
    $buttonDownload.BackColor = [System.Drawing.Color]::FromArgb(62,62,66) # Dark mode button color
    $buttonDownload.ForeColor = [System.Drawing.Color]::White

    $buttonDownload.Add_Click({
        DownloadRepos
    })

    # Schedule Backup button
    $buttonSchedule = New-Object Windows.Forms.Button
    $buttonSchedule.Text = "Schedule Daily Backup"
    $buttonSchedule.Size = New-Object Drawing.Size(150,50)
    $buttonSchedule.Location = New-Object Drawing.Point(200,50)
    $buttonSchedule.BackColor = [System.Drawing.Color]::FromArgb(62,62,66) # Dark mode button color
    $buttonSchedule.ForeColor = [System.Drawing.Color]::White

    $buttonSchedule.Add_Click({
        ScheduleBackup
    })

    $form.Controls.Add($buttonDownload)
    $form.Controls.Add($buttonSchedule)

    $form.Add_Shown({$form.Activate()})
    [void] $form.ShowDialog()
}

# Function to backup repositories
function DownloadRepos {
    try {
        $BackupDir = "$env:USERPROFILE\GitHub-BACKUPS"
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

        [System.Windows.Forms.MessageBox]::Show("Backup Completed: $ZipFile.")
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("An error occurred: $_")
    }
}

# Function to schedule daily backup
function ScheduleBackup {
    $BackupDir = "$env:USERPROFILE\GitHub-pwr-BACKUPS"
    $Date = Get-Date -Format "yyyy-MM-dd"
    $ZipFile = "$BackupDir\pwr-repo-backup-$Date.zip"
    $BackupScript = "$env:USERPROFILE\Bin\Run-GitHub-Backups.ps1"
    $TaskName = "GitHubBackup"
    $ScriptContent = @'
$BackupDir = "$env:USERPROFILE\GitHub-BACKUPS"
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

    if (!(Test-Path $env:USERPROFILE\Bin)) {
        New-Item -ItemType Directory -Path $env:USERPROFILE\Bin -Force
    }
    Set-Content -Path $BackupScript -Value $ScriptContent

    if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    }

    $Action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-ExecutionPolicy Bypass -File `"$BackupScript`""
    $Trigger = New-ScheduledTaskTrigger -Daily -At 3am
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    $Principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive

    Register-ScheduledTask -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal -TaskName $TaskName -Description "GitHub Repositories Backup"

    [System.Windows.Forms.MessageBox]::Show("Daily Backup Scheduled at 3am.")
}

# Show the form
Show-BackupForm
