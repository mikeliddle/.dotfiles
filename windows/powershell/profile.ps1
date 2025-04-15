Import-Module -Name posh-git
oh-my-posh init pwsh --config ~/.config/miliddle.omp.json | Invoke-Expression
function Invoke-SetDevLocation {
    param (
        [string]$SubPath = ""
    )
    $FullPath = Join-Path -Path "D:\" -ChildPath $SubPath
    Set-Location $FullPath
}

function Invoke-GitStatus {
    git status
}

function Invoke-GitBranch {
    git branch
}

function Invoke-OpenDevProject {
    param (
        [string]$SubPath = ""
    )
    $FullPath = Join-Path -Path $PWD.Path -ChildPath $SubPath
    if (-not (Test-Path -Path $FullPath)) {
        Write-Warning "The path '$FullPath' does not exist."
        return
    }

    $devContainerPath = Join-Path -Path $FullPath -ChildPath ".devcontainer"
    if (Test-Path -Path $devContainerPath) {
        devcontainer open $FullPath
        return
    }

    code $FullPath
}

Set-Alias -Name vi -value nvim
Set-Alias -Name dev -value Invoke-SetDevLocation
Set-Alias -Name gs -value Invoke-GitStatus
Set-Alias -Name gb -value Invoke-GitBranch
Set-Alias -Name open -value Invoke-OpenDevProject
Set-Alias -Name touch -value New-Item
Set-Alias -Name which -value Get-Command

if ($env:USERDOMAIN -eq "NORTHAMERICA") {
    ## for work ##
    Import-Module -Name IntunePS
    # Add CoreXT status to the posh-git prompt
    $GitPromptSettings.DefaultPromptSuffix.Text = '$($PSStyle.Foreground.BrightMagenta)$(Get-CorextPrompt)$($PSStyle.Reset)' + $($GitPromptSettings.DefaultPromptSuffix.Text)
    # Do a weekly check (in the background) for updates to the IntunePS module
    Find-IntunePSUpdates -Background
}

# Add GitHub CLI completion scripts
if (Get-Command -Name gh -ErrorAction SilentlyContinue) {
    Invoke-Expression -Command $(gh completion -s powershell | Out-String)
}

if (-not (Test-Path -Path "D:\")) {
    Write-Warning "D: drive is not mounted, repos may not be available"
}
else {
    # Set the default location to the D: drive
    if (-not ($PWD.Path -like "D:\*")) {
        Set-Location -Path "D:\"
    }
}

if (Test-Path -Path "D:\.dotfiles") {
    Start-Job -ScriptBlock {
        git pull D:\.dotfiles
        Copy-Item D:\.dotfiles\windows\powershell\profile.ps1 -Destination $Env:USERPROFILE\OneDrive\Documents\Powershell\Microsoft.PowerShell_profile.ps1 -Force
    } | Out-Null
}