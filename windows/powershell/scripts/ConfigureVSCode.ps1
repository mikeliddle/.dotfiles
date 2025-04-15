# Install recommended VS Code extensions
$ExtensionsFile = "shared/.vscode/extensions.json"
if (Test-Path $ExtensionsFile) {
    $Extensions = Get-Content $ExtensionsFile | ConvertFrom-Json

    foreach ($Extension in $Extensions.recommendations) {
        Write-Host "Installing VS Code extension: $Extension"
        if (-not (code --list-extensions | Where-Object { $_ -eq $Extension })) {
            code --install-extension $Extension
        }
    }
}
else {
    Write-Error "Extensions file $ExtensionsFile not found."
}

# Copy VS Code settings
$SettingsFile = "shared/.vscode/settings.json"
if (Test-Path $SettingsFile) {
    $SettingsPath = "$HOME\AppData\Roaming\Code\User\settings.json"
    if (-not (Test-Path $SettingsPath)) {
        New-Item -Path $SettingsPath -ItemType File -Force | Out-Null
    }
    Copy-Item -Path $SettingsFile -Destination $SettingsPath -Force
}
else {
    Write-Error "Settings file $SettingsFile not found."
}