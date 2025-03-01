#! Works on Windows, Mac and Linux
.{

    # Prompt for GitHub username
    Write-Host "Enter the GitHub username:" -ForegroundColor Magenta
    $username = Read-Host

    # Check if already authenticated
    $authStatus = gh auth status --hostname github.com 2>&1
    if ($authStatus -notmatch "You are not logged into any GitHub hosts") {
        Write-Host "You are already logged in to GitHub."
    }
    else {
        Write-Host "Logging in to GitHub..."
        gh auth login
    }

    # Fetch all repository names of the user
    $repos = gh repo list $username --json name --jq '.[].name'

    # Define the target directory
    $targetDir = "$env:USERPROFILE\Github"

    # Create the target directory if it doesn't exist
    if (-not (Test-Path -Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir
    }

    # Clone each repository using HTTPS into the target directory
    foreach ($repo in $repos) {
        git clone https://github.com/$username/$repo.git "$targetDir\$repo"
    }

}
