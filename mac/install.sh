#!/bin/bash

PACKAGE_FILE="./mac/packages.json"

# Install Xcode Command Line Tools
if ! xcode-select -p &> /dev/null; then
    echo "Installing Xcode Command Line Tools..."
    xcode-select --install || echo "Failed to install Xcode Command Line Tools"
else
    echo "Xcode Command Line Tools are already installed."
fi

# Install Homebrew if not installed
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || echo "Failed to install Homebrew"
else
    echo "Homebrew is already installed."
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq is required but not installed. Installing jq..."
    brew install jq || { echo "Failed to install jq. Exiting."; exit 1; }
fi

# Function to install a package
function install_package() {
    local package_name=$1
    if ! brew list "$package_name" &> /dev/null; then
        echo "Installing $package_name..."
        brew install "$package_name" || echo "Failed to install $package_name"
    else
        echo "$package_name is already installed."
    fi
}

# Set up Neovim configuration
NVIM_CONFIG_PATH="$HOME/.nvim"
if [[ ! -d "$NVIM_CONFIG_PATH" ]]; then
    mkdir -p "$NVIM_CONFIG_PATH"
    echo "Created Neovim configuration directory at $NVIM_CONFIG_PATH"
fi
cp -r shared/nvim/* "$NVIM_CONFIG_PATH" || echo "Failed to copy Neovim configuration files"

# Set up VSCode configuration
VSCODE_CONFIG_PATH="$HOME/Library/Application Support/Code/User"
if [[ ! -d "$VSCODE_CONFIG_PATH" ]]; then
    mkdir -p "$VSCODE_CONFIG_PATH"
    echo "Created VSCode configuration directory at $VSCODE_CONFIG_PATH"
fi
cp -r shared/.vscode/* "$VSCODE_CONFIG_PATH" || echo "Failed to copy VSCode configuration files"

git config --global push.autoSetupRemote true

# Create .zshrc and copy Zsh-related files
echo "Setting up Zsh configuration..."
mkdir -p ~/.zsh
cp -r mac/zsh/* ~/.zsh/

# Install required packages from the package file
if [[ -f "$PACKAGE_FILE" ]]; then
    PACKAGES=$(jq -r '.personal[].package' "$PACKAGE_FILE")
    for package in $PACKAGES; do
        install_package "$package"
    done
else
    echo "Package file $PACKAGE_FILE not found. Skipping package installation."
fi

echo "macOS setup complete!"