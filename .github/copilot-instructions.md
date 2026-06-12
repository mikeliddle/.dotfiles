# Copilot Instructions

## Build / Test / Lint

None — this is a configuration repository with install scripts, not a compiled project.

## Repository Overview

This is a cross-platform dotfiles repository that configures development environments on Windows, macOS, and Linux. It uses a platform-specific + shared architecture with automated installation scripts.

## Installation

```powershell
# Windows — full setup
.\install.ps1

# Windows — selective
.\install.ps1 -p   # packages only
.\install.ps1 -n   # neovim config only
.\install.ps1 -v   # vscode config only
```

```bash
# macOS / Linux — auto-detects OS via uname
./install.sh
```

## Architecture

### Platform Layout

- `windows/` — PowerShell scripts, DSC configs, Windows Terminal settings
- `mac/` — Homebrew-based install, Zsh config
- `linux/` — Apt-based install, Bash config
- `shared/` — Cross-platform configs: Neovim, VS Code, npm packages

### Installation Flow

**Windows** (`install.ps1`): Calls modular scripts in `windows/powershell/scripts/` sequentially — ConfigurePowershell → InstallPackages → ConfigureNVim → ConfigureVSCode → ConfigureWindows → ConfigureGit.

**macOS** (`mac/install.sh`): Bootstraps Homebrew, installs packages from `mac/packages.json` (split by `package` vs `cask` fields), then copies shared configs to `~/.config/`.

**Linux** (`linux/install.sh`): Uses apt with batch installation, downloads Neovim as AppImage, installs Zig from source, copies configs with `rsync --update`.

### Package Definitions

Each platform has a `packages.json` with categorized packages:
- Windows: `shared`, `personal`, `work` arrays (work = corporate domain machines)
- macOS: `personal` array with `name`, `package`, `cask` fields
- Linux: `personal` array with `name`, `package` fields
- `shared/npm/packages.json`: Global npm packages installed on all platforms

Windows also uses Winget DSC files (`windows/powershell/dsc/*.winget`) for declarative package state: `shared.winget`, `personal.winget`, `work.winget`.

### Work vs Personal Detection

Windows scripts check `$env:USERDOMAIN -eq "NORTHAMERICA"` to distinguish corporate machines from personal ones. This gates:
- Which packages get installed (work vs personal DSC configs)
- Git user.email/user.name (read from `.env` file)
- PowerShell profile behavior (IntunePS, CoreXT, module update checks)

## Conventions

### Shell Aliases Are Consistent Across Platforms

PowerShell profile, `.zshrc`, and `.bash_aliases` all define the same core aliases: `vi`/`vim` → nvim, `dev` → navigate to workspace, `gs` → git status, `gb` → git branch.

### Neovim Config Uses `miliddle` Namespace

All Neovim Lua modules live under `shared/nvim/lua/miliddle/`. The plugin manager is Lazy.nvim with plugins in `miliddle.plugins`. Leader key is `<Space>`. Editor defaults: 4-space indent, relative line numbers, 80-col indicator.

### Font Standardization

JetBrains Mono Nerd Font is used in Windows Terminal and VS Code.

### Git Configuration

- `push.autoSetupRemote = true` is set on all platforms
- Git credentials come from `.env` file (not committed — listed in `.gitignore`)
- `env.ps1` is the template showing the expected `.env` format

### Scripts Are Idempotent

Install scripts check for existing installations before acting (e.g., `brew list` checks, `cmp -s` file comparison on Linux, Winget DSC desired state). They're safe to re-run.

### The `open` Alias Detects Devcontainers

The PowerShell `open` alias (mapped to `Invoke-OpenDevProject`) checks for a `.devcontainer` directory in the target folder. If found, it opens the project in a VS Code devcontainer instead of a normal window.

### PowerShell Profile Auto-Syncs Dotfiles

The PowerShell profile runs a background job on load that pulls the dotfiles repo and copies the profile to OneDrive. Be careful not to break the `Start-Job` block at the end of `windows/powershell/profile.ps1`.

### VS Code Formatter Assignments

- JSON / JSONC / Markdown → Prettier
- C → clang-format
- GitHub Copilot is enabled for all file types
