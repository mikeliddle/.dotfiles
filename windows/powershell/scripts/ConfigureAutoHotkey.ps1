param(
    [string]$ScriptPath = "$env:USERPROFILE\AutoHotkey\WindowSlots.ahk",
    [string]$AutoHotkeyPath = "$env:ProgramFiles\AutoHotkey\v2\AutoHotkey64.exe"
)

$ErrorActionPreference = "Stop"

foreach ($path in @($ScriptPath, $AutoHotkeyPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required AutoHotkey file not found: $path"
    }
}

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Run ConfigureAutoHotkey.ps1 from an elevated PowerShell session."
}

$ScriptPath = (Resolve-Path -LiteralPath $ScriptPath).Path
$AutoHotkeyPath = (Resolve-Path -LiteralPath $AutoHotkeyPath).Path
$taskName = "MiliddleWindowSlots"
$user = $identity.Name

$action = New-ScheduledTaskAction -Execute $AutoHotkeyPath `
    -Argument "`"$ScriptPath`"" -WorkingDirectory (Split-Path -Parent $ScriptPath)
$logonTrigger = New-ScheduledTaskTrigger -AtLogOn -User $user
# Task Scheduler's session-state value 8 is workstation unlock.
$unlockClass = Get-CimClass -Namespace "Root\Microsoft\Windows\TaskScheduler" `
    -ClassName "MSFT_TaskSessionStateChangeTrigger"
$unlockTrigger = New-CimInstance -CimClass $unlockClass -ClientOnly `
    -Property @{ StateChange = [uint32]8; UserId = $user; Enabled = $true }
$taskPrincipal = New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew `
    -ExecutionTimeLimit ([TimeSpan]::Zero) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

Register-ScheduledTask -TaskName $taskName -Action $action `
    -Trigger @($logonTrigger, $unlockTrigger) -Principal $taskPrincipal -Settings $settings `
    -Description "Run AutoHotkey window slots elevated at login and workstation unlock." `
    -Force | Out-Null
Start-ScheduledTask -TaskName $taskName
Write-Host "AutoHotkey configured to start at login and workstation unlock."
