$PSVersion = $PSVersionTable.PSVersion.Major

if ($PSVersion -lt 7) {
    winget install --id Microsoft.Powershell
    # Make the default profile the VS Code PowerShell profile
    New-Item -ItemType SymbolicLink -Path $PROFILE -Target "~\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
    # Set PowerShell Core as the default shell
    $profilePath = [System.IO.Path]::Combine($env:USERPROFILE, 'Documents\PowerShell\profile.ps1')
    if (-not (Test-Path $profilePath)) {
        New-Item -Path $profilePath -ItemType File -Force | Out-Null
    }
    Add-Content -Path $profilePath -Value 'Set-DefaultShell pwsh'

    # Re-run the script in PowerShell Core
    Start-Process pwsh -ArgumentList '-File', $MyInvocation.MyCommand.Path
    exit
}
else {
    Write-Host "PowerShell Core is already installed."
}

Copy-Item windows/powershell/profile.ps1 $PROFILE -Force

Start-Job -ScriptBlock {
    Install-Module -Name posh-git -Force
} | Out-Null