# initial-setup-automation

Cross-platform development environment setup script.

Supports: Ubuntu/Debian, macOS (Intel/Apple Silicon), WSL2, Fedora, Arch Linux

## Quick Start

```bash
# One-liner install (no clone required)
curl -fsSL https://raw.githubusercontent.com/uniaevum/initial-setup-automation/main/install.sh | bash

# Or with options
curl -fsSL https://raw.githubusercontent.com/uniaevum/initial-setup-automation/main/install.sh | bash -s -- --skip-packages

# Or clone and run
git clone https://github.com/uniaevum/initial-setup-automation.git
cd initial-setup-automation
./install.sh
```

## What's Installed

### System Packages

| Category | Packages |
|----------|----------|
| Core utilities | curl, wget, git, vim, jq, yq, tree, htop |
| Modern CLI | ripgrep, fd, bat, eza, delta |
| Development | shellcheck, shfmt, gh (GitHub CLI) |

### Development Tools (via mise)

| Tool | Description |
|------|-------------|
| node | JavaScript runtime (v22 LTS) |
| python | Python (latest) |

## Options

```bash
./install.sh                  # Full installation
./install.sh --skip-packages  # Skip apt/brew packages
./install.sh --skip-mise      # Skip mise installation
./install.sh --mise-only      # Only install mise
./install.sh --help           # Show help
```

## Post-Installation

After installation, restart your shell:

```bash
source ~/.bashrc
```

If you skipped mise tools installation during setup:

```bash
mise install
```

## Useful Commands

```bash
mise list          # Show installed tools
mise install       # Install tools from config
mise use node@20   # Switch Node.js version
mise doctor        # Check mise health
mise upgrade       # Upgrade all tools
```

## Customization

### Adding mise tools

Edit `~/.config/mise/config.toml`:

```toml
[tools]
go = "latest"
deno = "latest"
```

Then run:

```bash
mise install
```

### Git Configuration

The script sets basic git defaults only if not already configured:
- `core.editor = vim`
- `init.defaultBranch = main`
- `pull.rebase = true`
- `push.autoSetupRemote = true`

To set your name and email:

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

## Directory Structure

```
.
├── install.sh      # Main setup script
└── README.md       # This file
```

## Platform Notes

### WSL2
- Docker should be installed on Windows with WSL integration enabled
- The script detects WSL automatically

### macOS
- Homebrew will be installed automatically if not present
- Works on both Intel and Apple Silicon

### Linux
- Supports apt (Ubuntu/Debian), dnf (Fedora), pacman (Arch)
- Modern CLI tools are installed from GitHub releases on apt-based systems

## Troubleshooting

### mise command not found

```bash
export PATH="$HOME/.local/bin:$PATH"
source ~/.bashrc
```

### mise tools fail to install

```bash
mise trust ~/.config/mise/config.toml
mise install
```

### Check mise health

```bash
mise doctor
```

## License

MIT
