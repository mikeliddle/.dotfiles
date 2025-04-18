# Check if oh-my-posh is already in PATH, if not, add it
$ompPath = "$env:LOCALAPPDATA\Programs\oh-my-posh\bin"
if (-not ($env:Path -split ';' | Where-Object { $_ -eq $ompPath })) {
    [Environment]::SetEnvironmentVariable('Path', "$env:Path;$ompPath", [EnvironmentVariableTarget]::User)
    Write-Output "oh-my-posh path added to environment variables."
}
else {
    Write-Output "oh-my-posh path already exists in environment variables."
}

# Check if JetBrains Mono Nerd Font is installed, if not, install it using oh-my-posh
$fontName = "JetBrainsMono Nerd Font"
if (-not (oh-my-posh font list | Select-String -Pattern $fontName)) {
    oh-my-posh font install "JetBrainsMono"
    Write-Output "JetBrains Mono Nerd Font installed."
}
else {
    Write-Output "JetBrains Mono Nerd Font is already installed."
}

if (-not (Test-Path -Path "~\.config")) {
    # Install oh-my-posh if not already installed

    New-Item -Path "~\.config" -ItemType Directory -Force | Out-Null
}

Copy-Item -Force shared/config/miliddle.omp.json ~/.config/
Copy-Item -Force windows/config/wt.json "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
Write-Output "Windows Terminal settings updated."
