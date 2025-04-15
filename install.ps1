param(
    [Parameter(Mandatory = $false)]
    [Alias("p")]
    [switch]$package,

    [Parameter(Mandatory = $false)]
    [Alias("n")]
    [switch]$nvim,

    [Parameter(Mandatory = $false)]
    [Alias("v")]
    [switch]$vscode
)

$ScriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path

if ($package) {
    & "$ScriptDirectory\windows\powershell\scripts\InstallPackages.ps1"
    exit
}

if ($nvim) {
    & "$ScriptDirectory\windows\powershell\scripts\ConfigureNVim.ps1"
    exit
}

if ($vscode) {
    & "$ScriptDirectory\windows\powershell\scripts\ConfigureVSCode.ps1"
    exit
}

& "$ScriptDirectory\windows\powershell\scripts\ConfigurePowershell.ps1"
& "$ScriptDirectory\windows\powershell\scripts\InstallPackages.ps1"

& "$ScriptDirectory\windows\powershell\scripts\ConfigureNVim.ps1"
& "$ScriptDirectory\windows\powershell\scripts\ConfigureVSCode.ps1"

& "$ScriptDirectory\windows\powershell\scripts\ConfigureWindows.ps1"
& "$ScriptDirectory\windows\powershell\scripts\ConfigureGit.ps1"
& "$ScriptDirectory\windows\powershell\scripts\ConfigurePosh.ps1"
