#!/bin/bash

PACKAGE_FILE="./linux/packages.json"
NVIM_CONFIG_PATH="$HOME/.config/nvim"

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
    sudo apt-get install -y jq || { echo "Failed to install jq. Exiting."; exit 1; }
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

cp "$BASHRC_SOURCE" "$HOME/.bashrc"
cp "$BASH_ALIASES_SOURCE" "$HOME/.bash_aliases"

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

# Install VSCode extensions from a list
VSCODE_EXTENSIONS_FILE="./shared/vscode/extensions.txt"

# Install VSCode extensions from shared/.vscode/extensions.json if it exists
VSCODE_EXT_JSON="shared/.vscode/extensions.json"
if [[ -f "$VSCODE_EXT_JSON" ]]; then
    echo "Installing VSCode extensions from $VSCODE_EXT_JSON..."
    EXTENSIONS=$(jq -r '.[]' "$VSCODE_EXT_JSON")
    for extension in $EXTENSIONS; do
        if ! code --list-extensions | grep -q "^$extension$"; then
            code --install-extension "$extension" || echo "Failed to install VSCode extension: $extension"
        else
            echo "VSCode extension $extension is already installed."
        fi
    done
else
    echo "VSCode extensions file $VSCODE_EXT_JSON not found. Skipping VSCode extension installation."
fi

git config --global push.autoSetupRemote true

echo "Linux setup complete!"