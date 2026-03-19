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

- `-p` - Only run the package install steps
- `-n` - Only copy over the neovim config

`.env` - create this file with the git config information applied in `ConfigureGit.ps1`

For an example, see `env`

## Features

- Cross-platform support for Windows, macOS, and Linux.
- Pre-configured Neovim setup.
- Recommended VS Code extensions.
- PowerShell and Zsh profiles for enhanced productivity.
- macOS Zsh setup bootstraps Oh My Zsh and enables Git-aware shell completion.
- macOS Hammerspoon window-slot macros for fast window recall.

## macOS Hammerspoon window slots

On macOS, the installer now sets up `Hammerspoon` and copies `mac/hammerspoon/init.lua` to `~/.hammerspoon/init.lua`.

Default shortcuts:

- `Alt` + `Shift` + `1..9` focuses the saved window in that slot, launching the saved app first if needed.
- `Alt` + `Shift` + `0` shows an overview of all saved slots.
- `Cmd` + `Alt` + `Shift` + `1..9` saves the currently focused window into that slot.
- `Alt` + `Shift` + `Left` snaps the frontmost window to the left half.
- `Alt` + `Shift` + `Right` snaps the frontmost window to the right half.
- `Alt` + `Shift` + `Up` maximizes the frontmost window.

The first time you launch Hammerspoon, macOS will prompt for Accessibility permissions so it can inspect and focus windows.

## Troubleshooting

- Ensure you have the required permissions to execute the scripts.
- For Windows, ensure `winget` is installed and available in your PATH.
- For macOS/Linux, ensure `bash` is installed and executable.

## Contributing

Feel free to submit pull requests or open issues for improvements or bug fixes.
