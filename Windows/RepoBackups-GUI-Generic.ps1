Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "GitHub Repo Cloner"
$form.Size = New-Object System.Drawing.Size(400, 250)
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$form.MaximizeBox = $false

$label = New-Object System.Windows.Forms.Label
$label.Text = "GitHub Username:"
$label.Location = New-Object System.Drawing.Point(20, 20)
$label.Size = New-Object System.Drawing.Size(120, 20)
$form.Controls.Add($label)

$usernameBox = New-Object System.Windows.Forms.TextBox
$usernameBox.Location = New-Object System.Drawing.Point(140, 18)
$usernameBox.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($usernameBox)

$folderLabel = New-Object System.Windows.Forms.Label
$folderLabel.Text = "Destination Folder:"
$folderLabel.Location = New-Object System.Drawing.Point(20, 50)
$folderLabel.Size = New-Object System.Drawing.Size(120, 20)
$form.Controls.Add($folderLabel)

$folderBox = New-Object System.Windows.Forms.TextBox
$folderBox.Location = New-Object System.Drawing.Point(140, 48)
$folderBox.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($folderBox)

$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Text = "Browse..."
$browseButton.Location = New-Object System.Drawing.Point(140, 75)
$browseButton.Add_Click({ SelectFolder })
$form.Controls.Add($browseButton)

$cloneButton = New-Object System.Windows.Forms.Button
$cloneButton.Text = "Clone Repos"
$cloneButton.Location = New-Object System.Drawing.Point(140, 110)
$cloneButton.Add_Click({ CloneRepos })
$form.Controls.Add($cloneButton)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Status: Waiting..."
$statusLabel.Location = New-Object System.Drawing.Point(20, 140)
$statusLabel.Size = New-Object System.Drawing.Size(350, 40)
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

  UpdateStatus "Checking authentication..."
  $authStatus = PowerShellExec("gh auth status --hostname github.com")
  if ($authStatus -match "You are not logged into any GitHub hosts") {
    UpdateStatus "Logging in to GitHub..."
    Start-Process pwsh -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command gh auth login; Read-Host 'Press Enter to continue'" -NoNewWindow -Wait
  }

  UpdateStatus "Fetching repositories..."
  $repos = PowerShellExec("gh repo list $username --json name --jq '.[].name'" ).Split("`n")

  if (-not (Test-Path -Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir | Out-Null
  }

  foreach ($repo in $repos) {
    if ($repo.Trim() -ne "") {
      UpdateStatus "Cloning $repo"
      & git clone "https://github.com/$username/$repo.git" "$targetDir\$repo"
    }
  }
  UpdateStatus "Cloning completed."
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
