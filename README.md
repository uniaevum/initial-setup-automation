# initial-setup-automation

Cross-platform development environment automation using Nix and Home Manager.

Supports: Linux, macOS (Intel/Apple Silicon), WSL2

## Quick Start

### One-liner (Remote Installation)

```bash
curl -fsSL https://raw.githubusercontent.com/uniaevum/initial-setup-automation/main/install.sh | bash
```

### Manual Installation

```bash
# Clone this repository
git clone https://github.com/uniaevum/initial-setup-automation.git
cd initial-setup-automation

# Run the bootstrap installer
./install.sh --skip-clone
```

## What's Included

### Shell Configuration

- Custom PS1 prompt with:
  - Platform indicator (WSL/Mac/Linux)
  - Git branch display
  - Exit code indicator
  - Colorful user@host:path format
- Bash and Zsh support
- Useful aliases for git, docker, kubernetes, terraform
- fzf integration for fuzzy finding
- direnv for automatic environment loading

### Development Tools (via mise)

| Tool | Description |
|------|-------------|
| docker-compose | Container orchestration |
| rust | Systems programming language |
| node | JavaScript runtime (LTS) |
| python | Python |
| terraform | Infrastructure as Code |
| kubectl | Kubernetes CLI |
| helm | Kubernetes package manager |
| helmfile | Helm chart deployment tool |

### Included Packages

- **Core utilities**: curl, wget, jq, yq, tree, htop, ripgrep, fd, bat, eza
- **Git tools**: git, gh (GitHub CLI), delta (better diff), pre-commit
- **Development**: vim, shellcheck, shfmt
- **Nix tools**: nil, nixpkgs-fmt, nix-tree

### Shell Aliases

```bash
# Git
g, gs, ga, gc, gp, gl, gd, gco, gb, glog

# Docker
d, dc, dps, dpsa

# Kubernetes
k, kgp, kgs, kgd

# Terraform
tf, tfi, tfp, tfa

# Home Manager
hm, hms, hme
```

## Installation

### Prerequisites

- Bash shell
- curl
- sudo access (for Nix installation)

### Install Everything

```bash
./install.sh
```

### Options

```bash
./install.sh --skip-nix     # Skip Nix installation (if already installed)
./install.sh --skip-apply   # Skip applying Home Manager configuration
./install.sh --skip-clone   # Skip cloning (use current directory)
./install.sh --dir <path>   # Custom installation directory
./install.sh --help         # Show help
```

### Remote with Options

```bash
# Skip Nix installation
curl -fsSL https://raw.githubusercontent.com/uniaevum/initial-setup-automation/main/install.sh | bash -s -- --skip-nix

# Custom installation directory
curl -fsSL https://raw.githubusercontent.com/uniaevum/initial-setup-automation/main/install.sh | bash -s -- --dir ~/dotfiles
```

## Post-Installation

After installation, restart your shell and run:

```bash
# Install mise-managed tools
mise-setup

# Install Claude CLI
install-claude
```

## Customization

### Git Configuration

Edit `modules/git.nix` to set your name and email:

```nix
programs.git = {
  userName = "Your Name";
  userEmail = "your.email@example.com";
};
```

### Adding New Configurations

1. Create a new entry in `flake.nix`:

```nix
homeConfigurations = {
  "your-username" = mkHomeConfig {
    system = "x86_64-linux";
    username = "your-username";
    homeDirectory = "/home/your-username";
  };
};
```

2. Apply the configuration:

```bash
home-manager switch --flake .#your-username
```

### Adding New Packages

Edit `modules/packages.nix`:

```nix
commonPackages = with pkgs; [
  # Add your packages here
  your-package
];
```

### Adding mise Tools

Edit `modules/mise.nix`:

```toml
[tools]
your-tool = "latest"
```

## Directory Structure

```
.
├── flake.nix           # Nix flake configuration
├── flake.lock          # Locked dependencies
├── install.sh          # Bootstrap installer
├── README.md           # This file
└── modules/
    ├── home.nix        # Main Home Manager module
    ├── shell.nix       # Shell (bash/zsh) configuration
    ├── git.nix         # Git configuration
    ├── mise.nix        # mise tool version manager
    └── packages.nix    # System packages
```

## Usage

### Apply Changes

After modifying any configuration:

```bash
# From this directory
home-manager switch --flake .#<config-name>

# Or using the alias
hms
```

### Update Dependencies

```bash
nix flake update
home-manager switch --flake .#<config-name>
```

### List Generations

```bash
home-manager generations
```

### Rollback

```bash
# Switch to a previous generation
home-manager generations
/nix/store/xxx-home-manager-generation/activate
```

## Platform-Specific Notes

### WSL2

- Docker should be installed on Windows with WSL integration enabled
- Use `wslview` to open files in Windows applications
- The prompt will show `[WSL]` as platform indicator

### macOS

- Some tools use prefixed coreutils (e.g., `gls` for `ls`)
- Docker Desktop should be installed separately

### Linux

- Full native support
- systemd services managed by Home Manager if enabled

## Troubleshooting

### Nix command not found after installation

```bash
# Source the Nix environment
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

### Home Manager switch fails

```bash
# Check Nix flake configuration
nix flake check

# Try with verbose output
home-manager switch --flake .#<config-name> --show-trace
```

### mise tools fail to install

```bash
# Trust the configuration first
mise trust ~/.config/mise/config.toml

# Then install
mise install
```

## Future Plans

- [ ] Neovim configuration with LSP support
- [ ] tmux configuration
- [ ] More shell completions
- [ ] Secret management integration

## License

MIT
