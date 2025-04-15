# .dotfiles

## Overview

This repository contains configuration files and scripts to set up a development environment across multiple platforms (Windows, macOS, Linux).

## Installation

Run the appropriate installation script based on your operating system:

- **Windows**: Run `install.ps1` in PowerShell.
- **Linux/macOS**: Run `install.sh` in a terminal.

```sh
# Example for Linux/macOS
./install.sh
```

```ps1
# Example for Windows
.\install.ps1
```

## Options

* `-p` - Only run the package install steps
* `-n` - Only copy over the neovim config

`.env` - create this file with the git config information applied in `ConfigureGit.ps1`

For an example, see `env`

## Features

- Cross-platform support for Windows, macOS, and Linux.
- Pre-configured Neovim setup.
- Recommended VS Code extensions.
- PowerShell and Zsh profiles for enhanced productivity.

## Troubleshooting

- Ensure you have the required permissions to execute the scripts.
- For Windows, ensure `winget` is installed and available in your PATH.
- For macOS/Linux, ensure `bash` is installed and executable.

## Contributing

Feel free to submit pull requests or open issues for improvements or bug fixes.
