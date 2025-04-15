# ConfigureGit.ps1

if (Test-Path .env) {
    . .env


    # Determine which configuration to apply
    if ($env:USERDOMAIN -eq "NORTHAMERICA") {
        git config --global user.email $workGitConfig.userEmail
        git config --global user.name $workGitConfig.userName
    }
    else {
        git config --global user.email $homeGitConfig.userEmail
        git config --global user.name $homeGitConfig.userName
    }

    # Set the default behavior for pushing branches
    git config --global push.autoSetupRemote true

    Write-Host "Git configuration applied successfully!" -ForegroundColor Green
}
