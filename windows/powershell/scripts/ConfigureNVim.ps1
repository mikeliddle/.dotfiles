# Set up Neovim configuration
$NvimConfigPath = "$env:LOCALAPPDATA\nvim"
if (-not (Test-Path $NvimConfigPath)) {
    New-Item -ItemType Directory -Path $NvimConfigPath -Force | Out-Null
}
Copy-Item -Path "shared\nvim\*" -Destination $NvimConfigPath -Recurse -Force
