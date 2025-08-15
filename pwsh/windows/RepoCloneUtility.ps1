#! ADMIN NOT REQUIRED
#! Description: A PowerShell script to back up GitHub repositories using the logged-in user's account via gh.
#! This Script Goes in $env:USERPROFILE\Bin

# Check if Git and gh are installed
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

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "🚀 Repo Clone Utility"
$form.Size = New-Object System.Drawing.Size(420, 320) # Increased height for better layout
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$form.Font = New-Object System.Drawing.Font("Segoe UI Emoji", 10)

# Title Label
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "Repo Clone Utility"
$titleLabel.AutoSize = $true
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI Emoji", 14, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::White
$titleLabel.Location = New-Object System.Drawing.Point(120, 10)
$form.Controls.Add($titleLabel)

# GitHub Username Label and TextBox
$usernameLabel = New-Object System.Windows.Forms.Label
$usernameLabel.Text = "👤 GitHub Username:"
$usernameLabel.Location = New-Object System.Drawing.Point(20, 50)
$usernameLabel.Size = New-Object System.Drawing.Size(140, 20)
$usernameLabel.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($usernameLabel)

$usernameBox = New-Object System.Windows.Forms.TextBox
$usernameBox.Location = New-Object System.Drawing.Point(160, 48)
$usernameBox.Size = New-Object System.Drawing.Size(220, 20)
$form.Controls.Add($usernameBox)

# Destination Folder Label and TextBox
$folderLabel = New-Object System.Windows.Forms.Label
$folderLabel.Text = "📂 Destination Folder:"
$folderLabel.Location = New-Object System.Drawing.Point(20, 80)
$folderLabel.Size = New-Object System.Drawing.Size(140, 20)
$folderLabel.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($folderLabel)

$folderBox = New-Object System.Windows.Forms.TextBox
$folderBox.Location = New-Object System.Drawing.Point(160, 78)
$folderBox.Size = New-Object System.Drawing.Size(220, 20)
$form.Controls.Add($folderBox)

# Browse Button
$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Text = "📁 Browse..."
$browseButton.Location = New-Object System.Drawing.Point(160, 105)
$browseButton.Size = New-Object System.Drawing.Size(220, 30)
$browseButton.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
$browseButton.ForeColor = [System.Drawing.Color]::White
$browseButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$browseButton.Add_Click({ SelectFolder })
$form.Controls.Add($browseButton)

# Clone Repos Button
$cloneButton = New-Object System.Windows.Forms.Button
$cloneButton.Text = "📥 Clone Repos"
$cloneButton.Location = New-Object System.Drawing.Point(160, 140)
$cloneButton.Size = New-Object System.Drawing.Size(220, 30)
$cloneButton.BackColor = [System.Drawing.Color]::FromArgb(34, 177, 76)
$cloneButton.ForeColor = [System.Drawing.Color]::White
$cloneButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$cloneButton.Add_Click({ CloneRepos })
$form.Controls.Add($cloneButton)

# Status Label
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "📡 Status: Waiting..."
$statusLabel.Location = New-Object System.Drawing.Point(20, 180)
$statusLabel.Size = New-Object System.Drawing.Size(380, 40)
$statusLabel.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($statusLabel)

# Function to ensure user is authenticated
function EnsureAuthenticated {
  UpdateStatus "🔄 Checking authentication..."
  $authStatus = PowerShellExec("gh auth status --hostname github.com")

  if ($authStatus -match "You are not logged into any GitHub hosts") {
    [System.Windows.Forms.MessageBox]::Show("You must log in to GitHub.", "Authentication Required", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    Start-Process pwsh -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command gh auth login; Read-Host 'Press Enter to continue'" -NoNewWindow -Wait

    # Re-check authentication after login
    $authStatus = PowerShellExec("gh auth status --hostname github.com")
    if ($authStatus -match "You are not logged into any GitHub hosts") {
      [System.Windows.Forms.MessageBox]::Show("Login failed. Please ensure you are logged in.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
      return $false
    }
  }

  # Fetch the authenticated username
  $loggedInUser = PowerShellExec("gh api user --jq .login").Trim()
  if ([string]::IsNullOrEmpty($loggedInUser)) {
    [System.Windows.Forms.MessageBox]::Show("Failed to fetch the authenticated user. Please check your login.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    return $false
  }

  # Compare authenticated user with the target username
  $targetUsername = $usernameBox.Text.Trim()
  if ($loggedInUser -ne $targetUsername) {
    [System.Windows.Forms.MessageBox]::Show("You are logged in as '$loggedInUser', but you are trying to clone repositories for '$targetUsername'. Please log in as the correct user - ONLY PUBLIC REPOS WILL BE CLONED.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    return $false
  }

  return $true
}

# Function to select destination folder
function SelectFolder {
  $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
  if ($folderDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    $folderBox.Text = $folderDialog.SelectedPath
  }
}

# Function to clone repositories
function CloneRepos {
  if (-not (EnsureAuthenticated)) {
    return
  }

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

  UpdateStatus "📡 Fetching repositories..."
  $repos = PowerShellExec("gh repo list $username --json name --jq '.[].name'").Split("`n")

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

# Function to execute PowerShell commands
function PowerShellExec($command) {
  try {
    return & pwsh -NoProfile -ExecutionPolicy Bypass -Command "$command" 2>&1
  }
  catch {
    return $_.Exception.Message
  }
}

# Function to update status label
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
