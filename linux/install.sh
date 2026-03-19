#!/bin/bash

# Set up error handling for critical failures only
set -o pipefail

PACKAGE_FILE="./linux/packages.json"
NVIM_CONFIG_PATH="$HOME/.config/nvim"

echo "Starting Linux setup..."

# Function to update apt cache if needed
APT_UPDATED=false
function update_apt_if_needed() {
    if [ "$APT_UPDATED" = false ]; then
        echo "Updating package cache..."
        sudo apt-get update -qq
        APT_UPDATED=true
    fi
}

# Function to check if a command exists
function command_exists() {
    command -v "$1" &> /dev/null
}

# Function to check if a package is installed
function package_installed() {
    dpkg -l "$1" &> /dev/null
}

# Function to install multiple packages efficiently
function install_packages() {
    local packages_to_install=()

    for package in "$@"; do
        if package_installed "$package"; then
            echo "$package is already installed."
        else
            echo "$package will be installed."
            packages_to_install+=("$package")
        fi
    done

    if [ ${#packages_to_install[@]} -gt 0 ]; then
        echo "Installing packages: ${packages_to_install[*]}"
        update_apt_if_needed
        sudo apt-get install -y "${packages_to_install[@]}" || echo "Failed to install some packages"
    else
        echo "All packages are already installed."
    fi
}

# Ensure jq is installed first (needed for parsing package file)
if ! package_installed "jq"; then
    echo "Installing jq (required for package management)..."
    update_apt_if_needed
    sudo apt-get install -y jq || { echo "Failed to install jq. Exiting."; exit 1; }
else
    echo "jq is already installed."
fi

# Install required packages from the package file
if [[ -f "$PACKAGE_FILE" ]]; then
    echo "Reading package list from $PACKAGE_FILE..."
    # Read all packages into an array
    mapfile -t PACKAGES < <(jq -r '.personal[].package' "$PACKAGE_FILE")

    if [ ${#PACKAGES[@]} -gt 0 ]; then
        install_packages "${PACKAGES[@]}"
    else
        echo "No packages found in $PACKAGE_FILE"
    fi
else
    echo "Error: Package file $PACKAGE_FILE not found. Skipping package installation."
fi

# Install latest Neovim
install_neovim() {
    local nvim_version_required="0.8.0"

    if command_exists "nvim"; then
        local current_version=$(nvim --version | head -n1 | grep -oP 'v\K[0-9]+\.[0-9]+\.[0-9]+' || echo "0.0.0")
        if [ "$(printf '%s\n' "$nvim_version_required" "$current_version" | sort -V | head -n1)" = "$nvim_version_required" ]; then
            echo "Neovim $current_version is already installed and meets requirements (>= $nvim_version_required)."
            return 0
        else
            echo "Neovim $current_version is installed but outdated. Upgrading..."
        fi
    fi

    echo "Installing latest Neovim from GitHub..."

    # Remove old neovim if installed via apt
    if package_installed "neovim"; then
        echo "Removing old neovim package..."
        sudo apt-get remove -y neovim
    fi

    # Create local bin directory if it doesn't exist
    mkdir -p "$HOME/.local/bin"

    # Download latest Neovim AppImage
    echo "Downloading latest Neovim AppImage..."
    local nvim_url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage"
    local nvim_path="$HOME/.local/bin/nvim"

    # Download the AppImage
    if ! curl -L "$nvim_url" -o "$nvim_path"; then
        echo "Failed to download Neovim AppImage"
        return 1
    fi

    # Make it executable
    chmod +x "$nvim_path"

    # Add ~/.local/bin to PATH if not already there
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
        export PATH="$HOME/.local/bin:$PATH"
    fi

    echo "Neovim AppImage installed successfully at $nvim_path"
    echo "You may need to source ~/.bashrc or restart your terminal for the PATH update to take effect"
}

install_neovim

# Install latest Zig
install_zig() {
    if command_exists "zig"; then
        local current_version=$(zig version 2>/dev/null || echo "unknown")
        echo "Zig $current_version is already installed."
        return 0
    fi

    echo "Installing Zig..."

    # Create local bin directory if it doesn't exist
    mkdir -p "$HOME/.local/bin"

    # Try to get the actual download URL from ziglang.org/download
    echo "Fetching Zig download information..."
    local download_page=$(curl -s https://ziglang.org/download/)

    # Look for the master build URL (most stable nightly)
    local zig_url=$(echo "$download_page" | grep -o 'https://[^"]*zig-linux-x86_64[^"]*\.tar\.xz' | head -1)

    if [ -z "$zig_url" ]; then
        echo "Could not find Zig download URL, trying fallback method..."
        # Fallback: try a known working URL pattern
        zig_url="https://ziglang.org/builds/zig-linux-x86_64-0.13.0.tar.xz"
    fi

    echo "Downloading Zig from: $zig_url"
    local temp_file="/tmp/zig-linux-x86_64.tar.xz"

    if ! curl -L "$zig_url" -o "$temp_file"; then
        echo "Failed to download Zig"
        return 1
    fi

    # Verify the file was downloaded correctly
    if [ ! -f "$temp_file" ] || [ ! -s "$temp_file" ]; then
        echo "Downloaded file is empty or missing"
        return 1
    fi

    # Extract to temporary directory
    local temp_dir="/tmp/zig-extract"
    rm -rf "$temp_dir"
    mkdir -p "$temp_dir"

    echo "Extracting Zig..."
    if ! tar -xf "$temp_file" -C "$temp_dir" --strip-components=1; then
        echo "Failed to extract Zig archive"
        return 1
    fi

    # Move to final location
    local zig_dir="$HOME/.local/zig"
    rm -rf "$zig_dir"
    mv "$temp_dir" "$zig_dir"

    # Create symlink
    ln -sf "$zig_dir/zig" "$HOME/.local/bin/zig"

    # Add ~/.local/bin to PATH if not already there
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
        export PATH="$HOME/.local/bin:$PATH"
    fi

    # Clean up
    rm -f "$temp_file"
    rm -rf "$temp_dir"

    echo "Zig installed successfully at $HOME/.local/zig"
    if command_exists "zig"; then
        echo "Zig version: $(zig version)"
    else
        echo "Zig installed, you may need to run: source ~/.bashrc"
    fi
}

install_zig

# Install Visual Studio Code
install_vscode() {
    if command_exists "code" && package_installed "code"; then
        echo "Visual Studio Code is already installed."
        return 0
    fi

    echo "Installing Visual Studio Code..."
    # Add Microsoft GPG key and repository
    if [ ! -f /etc/apt/trusted.gpg.d/packages.microsoft.gpg ]; then
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
        sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
        rm packages.microsoft.gpg
    fi

    if [ ! -f /etc/apt/sources.list.d/vscode.list ]; then
        sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
    fi

    # Update package cache and install
    update_apt_if_needed
    sudo apt-get install -y code || echo "Failed to install Visual Studio Code"
}

install_vscode

# Install .NET SDK
install_dotnet() {
    if command_exists "dotnet"; then
        echo ".NET SDK is already installed."
        return 0
    fi

    echo "Installing .NET SDK..."
    # Check if Microsoft package repository is already added
    if [ ! -f /etc/apt/sources.list.d/microsoft-prod.list ]; then
        # Add Microsoft package repository
        wget -q https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
        sudo dpkg -i packages-microsoft-prod.deb
        rm packages-microsoft-prod.deb
    fi

    update_apt_if_needed
    sudo apt-get install -y dotnet-sdk-6.0 || echo "Failed to install .NET SDK"
}

install_dotnet

# Install Docker
install_docker() {
    if command_exists "docker" && package_installed "docker-ce"; then
        echo "Docker is already installed."
        return 0
    fi

    echo "Installing Docker..."
    # Remove any existing Docker packages that might conflict
    sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

    # Add Docker's official GPG key
    if [ ! -f /usr/share/keyrings/docker-archive-keyring.gpg ]; then
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    fi

    # Add Docker repository
    if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    fi

    # Update package index and install Docker
    update_apt_if_needed
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io || echo "Failed to install Docker"

    # Add current user to docker group
    if ! groups $USER | grep -q docker; then
        sudo usermod -aG docker $USER
        echo "Docker installed. You may need to log out and back in to use Docker without sudo."
    fi
}

install_docker

# Install .bashrc and .bash_aliases
BASHRC_SOURCE="./linux/bash/.bashrc"
BASH_ALIASES_SOURCE="./linux/bash/.bash_aliases"

if [[ -f "$BASHRC_SOURCE" ]]; then
    if [[ ! -f "$HOME/.bashrc" ]] || ! cmp -s "$BASHRC_SOURCE" "$HOME/.bashrc"; then
        cp "$BASHRC_SOURCE" "$HOME/.bashrc"
        echo "Updated .bashrc"
    else
        echo ".bashrc is already up to date"
    fi
else
    echo "Warning: $BASHRC_SOURCE not found"
fi

if [[ -f "$BASH_ALIASES_SOURCE" ]]; then
    if [[ ! -f "$HOME/.bash_aliases" ]] || ! cmp -s "$BASH_ALIASES_SOURCE" "$HOME/.bash_aliases"; then
        cp "$BASH_ALIASES_SOURCE" "$HOME/.bash_aliases"
        echo "Updated .bash_aliases"
    else
        echo ".bash_aliases is already up to date"
    fi
else
    echo "Warning: $BASH_ALIASES_SOURCE not found"
fi

# Set up Neovim configuration
if [[ ! -d "$NVIM_CONFIG_PATH" ]]; then
    mkdir -p "$NVIM_CONFIG_PATH"
    echo "Created Neovim configuration directory at $NVIM_CONFIG_PATH"
fi

if [[ -d "shared/nvim" ]]; then
    # Use rsync for efficient copying (only copy changed files)
    if command_exists "rsync"; then
        rsync -av --update shared/nvim/ "$NVIM_CONFIG_PATH/"
        echo "Updated Neovim configuration"
    else
        cp -r shared/nvim/* "$NVIM_CONFIG_PATH"
        echo "Copied Neovim configuration"
    fi
else
    echo "Warning: shared/nvim directory not found"
fi

# Set up VSCode configuration
VSCODE_CONFIG_PATH="$HOME/.config/Code/User"
VSCODE_SETTINGS_SOURCE="./shared/.vscode/settings.json"

if [[ ! -d "$VSCODE_CONFIG_PATH" ]]; then
    mkdir -p "$VSCODE_CONFIG_PATH"
    echo "Created VSCode configuration directory at $VSCODE_CONFIG_PATH"
fi

if [[ -f "$VSCODE_SETTINGS_SOURCE" ]]; then
    if [[ ! -f "$VSCODE_CONFIG_PATH/settings.json" ]] || ! cmp -s "$VSCODE_SETTINGS_SOURCE" "$VSCODE_CONFIG_PATH/settings.json"; then
        cp "$VSCODE_SETTINGS_SOURCE" "$VSCODE_CONFIG_PATH/settings.json"
        echo "Updated VSCode settings"
    else
        echo "VSCode settings are already up to date"
    fi
else
    echo "Warning: $VSCODE_SETTINGS_SOURCE not found. Skipping VSCode settings installation."
fi

# Install VSCode extensions from shared/.vscode/extensions.json if it exists
VSCODE_EXT_JSON="shared/.vscode/extensions.json"
if [[ -f "$VSCODE_EXT_JSON" ]]; then
    echo "Checking VSCode extensions from $VSCODE_EXT_JSON..."

    # Get list of currently installed extensions once
    INSTALLED_EXTENSIONS=$(code --list-extensions 2>/dev/null || echo "")

    # Read extensions and check which ones need to be installed
    EXTENSIONS_TO_INSTALL=()
    while IFS= read -r extension; do
        if [[ -n "$extension" ]]; then
            if echo "$INSTALLED_EXTENSIONS" | grep -q "^$extension$"; then
                echo "VSCode extension $extension is already installed."
            else
                EXTENSIONS_TO_INSTALL+=("$extension")
            fi
        fi
    done < <(jq -r '.recommendations[]' "$VSCODE_EXT_JSON" 2>/dev/null)

    # Install missing extensions
    if [ ${#EXTENSIONS_TO_INSTALL[@]} -gt 0 ]; then
        echo "Installing ${#EXTENSIONS_TO_INSTALL[@]} VSCode extensions..."
        for extension in "${EXTENSIONS_TO_INSTALL[@]}"; do
            echo "Installing $extension..."
            code --install-extension "$extension" || echo "Failed to install VSCode extension: $extension"
        done
    else
        echo "All VSCode extensions are already installed."
    fi
else
    echo "VSCode extensions file $VSCODE_EXT_JSON not found. Skipping VSCode extension installation."
fi

git config --global push.autoSetupRemote true

echo "Linux setup complete!"