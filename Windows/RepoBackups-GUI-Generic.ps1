#! ADMIN NOT REQUIRED
#! Description: A PowerShell script to back up GitHub repositories using the logged-in user's account via gh.
#! This Script Goes in $env:USERPROFILE\Bin


# Check if git and gh are installed
function Install-RequiredTools {
  # Check if Git is installed
  if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Output "Installing Git..."
    winget install -e --id Git.Git
  }
  else {
    Write-Output "Git is already installed."
  }

  # Check if GitHub CLI (gh) is installed
  if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Output "Installing GH - GitHub CLI..."
    winget install -e --id GitHub.cli
  }
  else {
    Write-Output "GH - GitHub CLI is already installed."
  }
}

Install-RequiredTools


Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "🚀  GitHub Generic Repo Cloner Utility"
$form.Size = New-Object System.Drawing.Size(420, 270)
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$form.Font = New-Object System.Drawing.Font("Segoe UI Emoji", 10)

$label = New-Object System.Windows.Forms.Label
$label.Text = "👤 GitHub Username:"
$label.Location = New-Object System.Drawing.Point(20, 20)
$label.Size = New-Object System.Drawing.Size(140, 20)
$label.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($label)

$usernameBox = New-Object System.Windows.Forms.TextBox
$usernameBox.Location = New-Object System.Drawing.Point(160, 18)
$usernameBox.Size = New-Object System.Drawing.Size(220, 20)
$form.Controls.Add($usernameBox)

$folderLabel = New-Object System.Windows.Forms.Label
$folderLabel.Text = "📂 Destination Folder:"
$folderLabel.Location = New-Object System.Drawing.Point(20, 50)
$folderLabel.Size = New-Object System.Drawing.Size(140, 20)
$folderLabel.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($folderLabel)

$folderBox = New-Object System.Windows.Forms.TextBox
$folderBox.Location = New-Object System.Drawing.Point(160, 48)
$folderBox.Size = New-Object System.Drawing.Size(220, 20)
$form.Controls.Add($folderBox)

$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Text = "📁 Browse..."
$browseButton.Location = New-Object System.Drawing.Point(160, 75)
$browseButton.Size = New-Object System.Drawing.Size(220, 30)
$browseButton.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
$browseButton.ForeColor = [System.Drawing.Color]::White
$browseButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$browseButton.Add_Click({ SelectFolder })
$form.Controls.Add($browseButton)

$cloneButton = New-Object System.Windows.Forms.Button
$cloneButton.Text = "📥 Clone Repos"
$cloneButton.Location = New-Object System.Drawing.Point(160, 110)
$cloneButton.Size = New-Object System.Drawing.Size(220, 30)  # Same size as Browse button
$cloneButton.BackColor = [System.Drawing.Color]::FromArgb(34, 177, 76)  # Green color (RGB: 34, 177, 76)
$cloneButton.ForeColor = [System.Drawing.Color]::White
$cloneButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$cloneButton.Add_Click({ CloneRepos })
$form.Controls.Add($cloneButton)


$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "📡 Status: Waiting..."
$statusLabel.Location = New-Object System.Drawing.Point(20, 150)
$statusLabel.Size = New-Object System.Drawing.Size(380, 40)
$statusLabel.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($statusLabel)

function SelectFolder {
  $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
  if ($folderDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    $folderBox.Text = $folderDialog.SelectedPath
  }
}

function CloneRepos {
  $username = $usernameBox.Text.Trim()
  $targetDir = $folderBox.Text.Trim()

  if ([string]::IsNullOrEmpty($username)) {
    [System.Windows.Forms.MessageBox]::Show("Please enter a GitHub username.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    return
  }

  if ([string]::IsNullOrEmpty($targetDir)) {
    [System.Windows.Forms.MessageBox]::Show("Please select a destination folder.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    return
  }

  UpdateStatus "🔄 Checking authentication..."
  $authStatus = PowerShellExec("gh auth status --hostname github.com")
  if ($authStatus -match "You are not logged into any GitHub hosts") {
    UpdateStatus "🔑 Logging in to GitHub..."
    Start-Process pwsh -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command gh auth login; Read-Host 'Press Enter to continue'" -NoNewWindow -Wait
  }

  UpdateStatus "📡 Fetching repositories..."
  $repos = PowerShellExec("gh repo list $username --json name --jq '.[].name'" ).Split("`n")

  if (-not (Test-Path -Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir | Out-Null
  }

  foreach ($repo in $repos) {
    if ($repo.Trim() -ne "") {
      UpdateStatus "⏳ Cloning $repo"
      & git clone "https://github.com/$username/$repo.git" "$targetDir\$repo"
    }
  }
  UpdateStatus "✅ Cloning completed."
}

function PowerShellExec($command) {
  try {
    return & pwsh -NoProfile -ExecutionPolicy Bypass -Command "$command" 2>&1
  }
  catch {
    return $_.Exception.Message
  }
}

function UpdateStatus($message) {
  if ($form.InvokeRequired) {
    $form.Invoke([Action] { $statusLabel.Text = $message })
  }
  else {
    $statusLabel.Text = $message
  }
}

[System.Windows.Forms.Application]::EnableVisualStyles()
$form.ShowDialog()
