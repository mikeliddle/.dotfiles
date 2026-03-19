#!/bin/bash

# Function to install a package
function install_package() {
    local package_name="$1"
    if ! brew list "$package_name" &> /dev/null; then
        echo "Installing $package_name..."
        brew install "$package_name" || echo "Failed to install $package_name"
    else
        echo "$package_name is already installed."
    fi
}

function install_cask() {
    local cask_name="$1"
    if ! brew list --cask "$cask_name" &> /dev/null; then
        echo "Installing $cask_name..."
        brew install --cask "$cask_name" || echo "Failed to install $cask_name"
    else
        echo "$cask_name is already installed."
    fi
}

function install_oh_my_zsh() {
    local oh_my_zsh_dir="$HOME/.oh-my-zsh"
    local installer_path

    if [[ -d "$oh_my_zsh_dir" ]]; then
        echo "Oh My Zsh is already installed."
        return 0
    fi

    echo "Installing Oh My Zsh..."
    installer_path="$(mktemp)"

    if ! curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o "$installer_path"; then
        rm -f "$installer_path"
        echo "Failed to download Oh My Zsh installer."
        return 1
    fi

    if ! RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh "$installer_path" --unattended; then
        rm -f "$installer_path"
        echo "Failed to install Oh My Zsh."
        return 1
    fi

    rm -f "$installer_path"
}

function enforce_dark_mode() {
    echo "Enforcing macOS dark mode..."

    defaults write -g AppleInterfaceStyleSwitchesAutomatically -bool false

    if osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true' &> /dev/null; then
        echo "macOS appearance set to dark mode."
        return 0
    fi

    defaults write -g AppleInterfaceStyle -string "Dark"
    echo "macOS appearance preference set to dark mode. Log out and back in if the change does not apply immediately."
}

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

# Install required packages from the package file
if [[ -f "$PACKAGE_FILE" ]]; then
    PACKAGES=$(jq -r '.personal[].package' "$PACKAGE_FILE")
    for package in $PACKAGES; do
        install_package "$package"
    done
else
    echo "Package file $PACKAGE_FILE not found. Skipping package installation."
fi

# Install required casks from the package file
if [[ -f "$PACKAGE_FILE" ]]; then
    CASKS=$(jq -r '.personal[].cask' "$PACKAGE_FILE")
    for cask in $CASKS; do
        install_cask "$cask"
    done
else
    echo "Package file $PACKAGE_FILE not found. Skipping cask installation."
fi

# Set up Neovim configuration
NVIM_CONFIG_PATH="$HOME/.config/nvim"
if [[ ! -d "$NVIM_CONFIG_PATH" ]]; then
    mkdir -p "$NVIM_CONFIG_PATH"
    echo "Created Neovim configuration directory at $NVIM_CONFIG_PATH"
fi
cp -r shared/nvim/* "$NVIM_CONFIG_PATH" || echo "Failed to copy Neovim configuration files"

# Create .zshrc and copy Zsh-related files
echo "Setting up Zsh configuration..."
install_oh_my_zsh || exit 1
mkdir -p ~/.zsh
cp -r mac/zsh/* ~/.zsh/
cp mac/.zshrc ~/.zshrc

enforce_dark_mode

# Set up Hammerspoon configuration
HAMMERSPOON_CONFIG_PATH="$HOME/.hammerspoon"
if [[ ! -d "$HAMMERSPOON_CONFIG_PATH" ]]; then
    mkdir -p "$HAMMERSPOON_CONFIG_PATH"
    echo "Created Hammerspoon configuration directory at $HAMMERSPOON_CONFIG_PATH"
fi
cp -r mac/hammerspoon/* "$HAMMERSPOON_CONFIG_PATH" || echo "Failed to copy Hammerspoon configuration files"

# Set up VSCode configuration
VSCODE_CONFIG_PATH="$HOME/Library/Application Support/Code/User"
if [[ ! -d "$VSCODE_CONFIG_PATH" ]]; then
    mkdir -p "$VSCODE_CONFIG_PATH"
    echo "Created VSCode configuration directory at $VSCODE_CONFIG_PATH"
fi
cp -r shared/.vscode/* "$VSCODE_CONFIG_PATH" || echo "Failed to copy VSCode configuration files"

# Install VSCode extensions from shared/.vscode/extensions.json if it exists
VSCODE_EXT_JSON="shared/.vscode/extensions.json"
if [[ -f "$VSCODE_EXT_JSON" ]]; then
    echo "Installing VSCode extensions from $VSCODE_EXT_JSON..."
    EXTENSIONS=$(jq -r '.recommendations[]' "$VSCODE_EXT_JSON")
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

echo "macOS setup complete!"
brew update && brew upgrade &
