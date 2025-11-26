#!/usr/bin/env bash
#
# Initial setup script for development environment
# Supports: Ubuntu/Debian, macOS, WSL
#
# Usage:
#   ./install.sh
#   ./install.sh --skip-packages   # Skip system package installation
#   ./install.sh --skip-mise       # Skip mise installation
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Detect platform
detect_platform() {
    if [[ -f /proc/sys/fs/binfmt_misc/WSLInterop ]] || [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
        echo "wsl"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "darwin"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

# Detect package manager
detect_package_manager() {
    if command -v apt-get &> /dev/null; then
        echo "apt"
    elif command -v brew &> /dev/null; then
        echo "brew"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v pacman &> /dev/null; then
        echo "pacman"
    else
        echo "unknown"
    fi
}

# Install Homebrew on macOS if not present
install_homebrew() {
    if ! command -v brew &> /dev/null; then
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add to PATH for current session
        if [[ -f /opt/homebrew/bin/brew ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -f /usr/local/bin/brew ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
        log_success "Homebrew installed"
    else
        log_info "Homebrew already installed"
    fi
}

# Install system packages
install_packages() {
    local pkg_manager=$1

    log_info "Installing system packages via $pkg_manager..."

    case "$pkg_manager" in
        apt)
            sudo apt-get update
            sudo apt-get install -y \
                curl \
                wget \
                git \
                vim \
                jq \
                tree \
                htop \
                unzip \
                zip \
                gnupg \
                ca-certificates \
                build-essential \
                file \
                procps \
                shellcheck
            ;;
        brew)
            brew install \
                curl \
                wget \
                git \
                vim \
                jq \
                yq \
                tree \
                htop \
                ripgrep \
                fd \
                bat \
                eza \
                git-delta \
                ncdu \
                gnupg \
                shellcheck \
                shfmt \
                gh
            ;;
        dnf)
            sudo dnf install -y \
                curl \
                wget \
                git \
                vim \
                jq \
                tree \
                htop \
                unzip \
                zip \
                gnupg2 \
                file \
                procps-ng \
                ShellCheck
            ;;
        pacman)
            sudo pacman -Syu --noconfirm \
                curl \
                wget \
                git \
                vim \
                jq \
                tree \
                htop \
                unzip \
                zip \
                gnupg \
                file \
                procps-ng \
                shellcheck
            ;;
        *)
            log_warn "Unknown package manager. Skipping system packages."
            return 1
            ;;
    esac

    log_success "System packages installed"
}

# Install modern CLI tools on apt-based systems (not available in default repos)
install_modern_tools_apt() {
    log_info "Installing modern CLI tools..."

    # ripgrep
    if ! command -v rg &> /dev/null; then
        log_info "Installing ripgrep..."
        curl -LO https://github.com/BurntSushi/ripgrep/releases/download/14.1.0/ripgrep_14.1.0-1_amd64.deb
        sudo dpkg -i ripgrep_14.1.0-1_amd64.deb
        rm ripgrep_14.1.0-1_amd64.deb
    fi

    # fd
    if ! command -v fd &> /dev/null && ! command -v fdfind &> /dev/null; then
        log_info "Installing fd..."
        curl -LO https://github.com/sharkdp/fd/releases/download/v10.2.0/fd_10.2.0_amd64.deb
        sudo dpkg -i fd_10.2.0_amd64.deb
        rm fd_10.2.0_amd64.deb
    fi

    # bat
    if ! command -v bat &> /dev/null && ! command -v batcat &> /dev/null; then
        log_info "Installing bat..."
        curl -LO https://github.com/sharkdp/bat/releases/download/v0.24.0/bat_0.24.0_amd64.deb
        sudo dpkg -i bat_0.24.0_amd64.deb
        rm bat_0.24.0_amd64.deb
    fi

    # eza (modern ls)
    if ! command -v eza &> /dev/null; then
        log_info "Installing eza..."
        sudo mkdir -p /etc/apt/keyrings
        wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
        sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
        sudo apt-get update
        sudo apt-get install -y eza
    fi

    # delta (better git diff)
    if ! command -v delta &> /dev/null; then
        log_info "Installing delta..."
        curl -LO https://github.com/dandavison/delta/releases/download/0.18.2/git-delta_0.18.2_amd64.deb
        sudo dpkg -i git-delta_0.18.2_amd64.deb
        rm git-delta_0.18.2_amd64.deb
    fi

    # GitHub CLI
    if ! command -v gh &> /dev/null; then
        log_info "Installing GitHub CLI..."
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt-get update
        sudo apt-get install -y gh
    fi

    # yq
    if ! command -v yq &> /dev/null; then
        log_info "Installing yq..."
        sudo curl -L https://github.com/mikefarah/yq/releases/download/v4.44.3/yq_linux_amd64 -o /usr/local/bin/yq
        sudo chmod +x /usr/local/bin/yq
    fi

    log_success "Modern CLI tools installed"
}

# Install mise
install_mise() {
    if command -v mise &> /dev/null; then
        log_info "mise already installed"
        return 0
    fi

    log_info "Installing mise..."
    curl https://mise.run | sh

    # Add mise to PATH for current session
    export PATH="$HOME/.local/bin:$PATH"

    log_success "mise installed"
}

# Setup mise configuration
setup_mise_config() {
    local config_dir="$HOME/.config/mise"
    local config_file="$config_dir/config.toml"

    log_info "Setting up mise configuration..."

    mkdir -p "$config_dir"

    cat > "$config_file" << 'EOF'
[settings]
# Automatically trust all .mise.toml files in trusted directories
trusted_config_paths = ["~/workspace"]

# Use verbose output
verbose = false

# Experimental features
experimental = true

# Always keep downloaded archives
always_keep_download = true

# Plugin update interval (hours)
plugin_autoupdate_last_check_duration = "168h"

[tools]
# Programming languages
node = "22"
python = "latest"

# Version aliases
[alias.node.versions]
lts = "22"
EOF

    log_success "mise configuration created at $config_file"
}

# Add mise to shell configuration (append only, don't overwrite)
setup_shell_integration() {
    log_info "Setting up shell integration..."

    local mise_init='
# mise (runtime version manager)
export PATH="$HOME/.local/bin:$PATH"
if command -v mise &> /dev/null; then
    eval "$(mise activate bash)"
fi
'

    local mise_init_zsh='
# mise (runtime version manager)
export PATH="$HOME/.local/bin:$PATH"
if command -v mise &> /dev/null; then
    eval "$(mise activate zsh)"
fi
'

    # Add to .bashrc if not already present
    if [[ -f "$HOME/.bashrc" ]]; then
        if ! grep -q "mise activate" "$HOME/.bashrc"; then
            echo "$mise_init" >> "$HOME/.bashrc"
            log_info "Added mise to ~/.bashrc"
        else
            log_info "mise already in ~/.bashrc"
        fi
    fi

    # Add to .zshrc if it exists and not already present
    if [[ -f "$HOME/.zshrc" ]]; then
        if ! grep -q "mise activate" "$HOME/.zshrc"; then
            echo "$mise_init_zsh" >> "$HOME/.zshrc"
            log_info "Added mise to ~/.zshrc"
        else
            log_info "mise already in ~/.zshrc"
        fi
    fi

    # Add to .profile for login shells
    if [[ -f "$HOME/.profile" ]]; then
        if ! grep -q 'HOME/.local/bin' "$HOME/.profile"; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.profile"
            log_info "Added ~/.local/bin to ~/.profile"
        fi
    fi

    log_success "Shell integration configured"
}

# Install mise tools
install_mise_tools() {
    log_info "Installing mise-managed tools..."

    # Ensure mise is in PATH
    export PATH="$HOME/.local/bin:$PATH"

    # Trust and install
    mise trust "$HOME/.config/mise/config.toml"
    mise install

    log_success "mise tools installed"
    echo ""
    log_info "Installed tools:"
    mise list
}

# Setup git configuration (only if not already configured)
setup_git() {
    log_info "Setting up git configuration..."

    # Only set defaults if not already configured
    if [[ -z "$(git config --global core.editor 2>/dev/null)" ]]; then
        git config --global core.editor "vim"
    fi

    if [[ -z "$(git config --global init.defaultBranch 2>/dev/null)" ]]; then
        git config --global init.defaultBranch "main"
    fi

    if [[ -z "$(git config --global pull.rebase 2>/dev/null)" ]]; then
        git config --global pull.rebase true
    fi

    if [[ -z "$(git config --global push.autoSetupRemote 2>/dev/null)" ]]; then
        git config --global push.autoSetupRemote true
    fi

    # Configure delta if available
    if command -v delta &> /dev/null; then
        if [[ -z "$(git config --global core.pager 2>/dev/null)" ]]; then
            git config --global core.pager "delta"
            git config --global interactive.diffFilter "delta --color-only"
            git config --global delta.navigate true
            git config --global delta.side-by-side true
            git config --global merge.conflictstyle "diff3"
        fi
    fi

    log_success "Git configuration done"
}

# Print usage
print_usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Initial setup script for development environment."
    echo ""
    echo "Options:"
    echo "  --skip-packages    Skip system package installation"
    echo "  --skip-mise        Skip mise installation and configuration"
    echo "  --mise-only        Only install/setup mise (skip packages)"
    echo "  --help, -h         Show this help message"
}

# Print next steps
print_next_steps() {
    echo ""
    log_success "Installation complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Restart your shell or run: source ~/.bashrc"
    echo "  2. Run 'mise install' to install development tools"
    echo ""
    echo "Useful commands:"
    echo "  mise list          - Show installed tools"
    echo "  mise install       - Install tools from config"
    echo "  mise use node@20   - Switch Node.js version"
    echo "  mise doctor        - Check mise health"
    echo ""
}

# Main function
main() {
    echo "=========================================="
    echo "  Development Environment Setup"
    echo "=========================================="
    echo ""

    local platform
    local pkg_manager
    platform=$(detect_platform)
    pkg_manager=$(detect_package_manager)

    log_info "Detected platform: $platform"
    log_info "Detected package manager: $pkg_manager"

    # Parse arguments
    local skip_packages=false
    local skip_mise=false
    local mise_only=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-packages)
                skip_packages=true
                shift
                ;;
            --skip-mise)
                skip_mise=true
                shift
                ;;
            --mise-only)
                mise_only=true
                shift
                ;;
            --help|-h)
                print_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                print_usage
                exit 1
                ;;
        esac
    done

    # Install Homebrew on macOS first
    if [[ "$platform" == "darwin" ]]; then
        install_homebrew
        pkg_manager="brew"
    fi

    # Install system packages
    if [[ "$skip_packages" == "false" ]] && [[ "$mise_only" == "false" ]]; then
        install_packages "$pkg_manager"

        # Install modern tools on apt-based systems
        if [[ "$pkg_manager" == "apt" ]]; then
            install_modern_tools_apt
        fi

        # Setup git
        setup_git
    else
        log_warn "Skipping system package installation"
    fi

    # Install and configure mise
    if [[ "$skip_mise" == "false" ]]; then
        install_mise
        setup_mise_config
        setup_shell_integration

        # Ask if user wants to install mise tools now
        echo ""
        read -p "Install mise-managed tools now? (node, python, rust, etc.) [y/N] " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_mise_tools
        else
            log_info "Skipped. Run 'mise install' later to install tools."
        fi
    else
        log_warn "Skipping mise installation"
    fi

    print_next_steps
}

main "$@"
