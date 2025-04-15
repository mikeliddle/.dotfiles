#!/bin/bash

PACKAGE_FILE="./linux/packages.json"
NVIM_CONFIG_PATH="$HOME/.nvim"

# Function to check if a command exists
function command_exists() {
    command -v "$1" &> /dev/null
}

# Function to install a package
function install_package() {
    local package_name=$1
    if ! command_exists "$package_name"; then
        echo "Installing $package_name..."
        sudo apt-get install -y "$package_name" || echo "Failed to install $package_name"
    else
        echo "$package_name is already installed."
    fi
}

# Ensure jq is installed
if ! command_exists "jq"; then
    echo "Error: jq is required but not installed. Please install jq and re-run the script."
    exit 1
fi

# Install required packages from the package file
if [[ -f "$PACKAGE_FILE" ]]; then
    echo "Reading package list from $PACKAGE_FILE..."
    PACKAGES=$(jq -r '.personal[].package' "$PACKAGE_FILE")
    for package in $PACKAGES; do
        install_package "$package"
    done
else
    echo "Error: Package file $PACKAGE_FILE not found. Skipping package installation."
fi

# Install .bashrc and .bash_aliases
BASHRC_SOURCE="./linux/bash/.bashrc"
BASH_ALIASES_SOURCE="./linux/bash/.bash_aliases"

if [[ -f "$BASHRC_SOURCE" ]]; then
    cp "$BASHRC_SOURCE" "$HOME/.bashrc"
    echo "Installed .bashrc to $HOME"
else
    echo "Error: $BASHRC_SOURCE not found. Skipping .bashrc installation."
fi

if [[ -f "$BASH_ALIASES_SOURCE" ]]; then
    cp "$BASH_ALIASES_SOURCE" "$HOME/.bash_aliases"
    echo "Installed .bash_aliases to $HOME"
else
    echo "Error: $BASH_ALIASES_SOURCE not found. Skipping .bash_aliases installation."
fi

# Set up Neovim configuration
if [[ ! -d "$NVIM_CONFIG_PATH" ]]; then
    mkdir -p "$NVIM_CONFIG_PATH"
    echo "Created Neovim configuration directory at $NVIM_CONFIG_PATH"
fi
cp -r shared/nvim/* "$NVIM_CONFIG_PATH"

# Set up VSCode configuration
VSCODE_CONFIG_PATH="$HOME/.config/Code/User"
VSCODE_SETTINGS_SOURCE="./shared/vscode/settings.json"

if [[ ! -d "$VSCODE_CONFIG_PATH" ]]; then
    mkdir -p "$VSCODE_CONFIG_PATH"
    echo "Created VSCode configuration directory at $VSCODE_CONFIG_PATH"
fi

if [[ -f "$VSCODE_SETTINGS_SOURCE" ]]; then
    cp "$VSCODE_SETTINGS_SOURCE" "$VSCODE_CONFIG_PATH/settings.json"
    echo "Installed VSCode settings to $VSCODE_CONFIG_PATH"
else
    echo "Error: $VSCODE_SETTINGS_SOURCE not found. Skipping VSCode settings installation."
fi

git config --global push.autoSetupRemote true

echo "Linux setup complete!"