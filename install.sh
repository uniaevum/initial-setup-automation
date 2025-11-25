#!/usr/bin/env bash
#
# Bootstrap script for installing Nix and Home Manager
# Supports: Linux, macOS, WSL
#
# Usage:
#   Local:  ./install.sh
#   Remote: curl -fsSL https://raw.githubusercontent.com/uniaevum/initial-setup-automation/main/install.sh | bash
#

set -euo pipefail

# Configuration
REPO_URL="https://github.com/uniaevum/initial-setup-automation.git"
REPO_BRANCH="main"
INSTALL_DIR="$HOME/.config/home-manager-config"

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

# Detect architecture
detect_arch() {
    local arch
    arch=$(uname -m)
    case "$arch" in
        x86_64)  echo "x86_64" ;;
        aarch64) echo "aarch64" ;;
        arm64)   echo "aarch64" ;;
        *)       echo "unknown" ;;
    esac
}

# Get the appropriate Home Manager configuration name
get_config_name() {
    local platform=$1
    local arch=$2
    local username=${3:-$(whoami)}

    case "$platform" in
        darwin)
            if [[ "$arch" == "aarch64" ]]; then
                echo "${username}-darwin-arm"
            else
                echo "${username}-darwin-x86"
            fi
            ;;
        linux|wsl)
            if [[ "$arch" == "aarch64" ]]; then
                echo "${username}-linux-arm"
            else
                echo "${username}"
            fi
            ;;
        *)
            echo "${username}"
            ;;
    esac
}

# Check if Nix is installed
check_nix() {
    if command -v nix &> /dev/null; then
        return 0
    fi
    return 1
}

# Check if Home Manager is installed
check_home_manager() {
    if command -v home-manager &> /dev/null; then
        return 0
    fi
    return 1
}

# Source Nix environment
source_nix() {
    if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        # shellcheck source=/dev/null
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    elif [[ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]]; then
        # shellcheck source=/dev/null
        . "$HOME/.nix-profile/etc/profile.d/nix.sh"
    fi
}

# Install Nix
install_nix() {
    log_info "Installing Nix..."

    if check_nix; then
        log_warn "Nix is already installed"
        return 0
    fi

    # Use the Determinate Nix Installer for better defaults
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

    log_success "Nix installed successfully"

    # Source Nix
    source_nix
}

# Check SSH key and show instructions if missing
check_ssh_key() {
    local ssh_key="$HOME/.ssh/id_ed25519"

    if [[ -f "$ssh_key" ]]; then
        log_info "SSH key found: $ssh_key"
        return 0
    fi

    log_warn "No default SSH key found at $ssh_key"
    echo ""
    echo "Some tools (like mise/pyenv for Python) require SSH access to GitHub."
    echo "To create an SSH key, run:"
    echo ""
    echo "  ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -C \"$(whoami)@$(hostname)\""
    echo ""
    echo "Then add the public key to GitHub:"
    echo "  cat ~/.ssh/id_ed25519.pub"
    echo ""
    echo "Or visit: https://github.com/settings/ssh/new"
    echo ""
}

# Clone or update repository
setup_repo() {
    local config_dir=$1

    log_info "Setting up configuration repository..."

    if [[ -d "$config_dir/.git" ]]; then
        log_info "Repository exists, pulling latest changes..."
        cd "$config_dir"
        git pull origin "$REPO_BRANCH" || log_warn "Could not pull latest changes"
    else
        log_info "Cloning repository..."
        rm -rf "$config_dir"
        git clone --branch "$REPO_BRANCH" "$REPO_URL" "$config_dir"
    fi

    # Replace __USERNAME__ placeholder with actual username
    configure_username "$config_dir"

    log_success "Repository ready at $config_dir"
}

# Configure username in flake.nix
configure_username() {
    local config_dir=$1
    local current_user
    current_user=$(whoami)
    local flake_file="$config_dir/flake.nix"

    if grep -q "__USERNAME__" "$flake_file" 2>/dev/null; then
        log_info "Configuring username: $current_user"
        sed -i "s/__USERNAME__/$current_user/g" "$flake_file"
    fi
}

# Setup the flake configuration
setup_flake() {
    log_info "Setting up flake configuration..."

    # Ensure experimental features are enabled
    mkdir -p "$HOME/.config/nix"
    if ! grep -q "experimental-features" "$HOME/.config/nix/nix.conf" 2>/dev/null; then
        echo "experimental-features = nix-command flakes" >> "$HOME/.config/nix/nix.conf"
    fi

    log_success "Flake configuration ready"
}

# Apply Home Manager configuration
apply_home_manager() {
    local config_dir=$1
    local platform=$2
    local arch=$3
    local config_name
    config_name=$(get_config_name "$platform" "$arch")

    log_info "Applying Home Manager configuration: $config_name"

    cd "$config_dir"

    # First time: bootstrap Home Manager
    if ! check_home_manager; then
        log_info "Bootstrapping Home Manager..."
        nix run home-manager/master -- switch --flake ".#${config_name}" -b backup
    else
        home-manager switch --flake ".#${config_name}" -b backup
    fi

    log_success "Home Manager configuration applied"
}

# Post-installation setup
post_install() {
    log_info "Running post-installation setup..."

    # Source nix again to ensure new paths are available
    source_nix

    # Setup mise tools
    if command -v mise &> /dev/null; then
        log_info "Setting up mise tools..."
        mise trust ~/.config/mise/config.toml 2>/dev/null || true
        mise install || log_warn "Some mise tools may have failed to install"
    fi

    log_success "Post-installation complete"
}

# Print next steps
print_next_steps() {
    local platform=$1
    local config_dir=$2

    echo ""
    log_success "Installation complete!"
    echo ""
    echo "Configuration directory: $config_dir"
    echo ""
    echo "Next steps:"
    echo "  1. Restart your shell or run: source ~/.bashrc"
    echo "  2. Run 'mise-setup' to install development tools"
    echo "  3. Run 'install-claude' to install Claude CLI"
    echo ""
    echo "Useful commands:"
    echo "  cd $config_dir"
    echo "  home-manager switch --flake .#<config-name>  - Apply changes"
    echo "  home-manager generations                      - List generations"
    echo "  nix flake update                              - Update flake inputs"
    echo ""
    echo "To customize your configuration:"
    echo "  1. Edit files in $config_dir/modules/"
    echo "  2. Run: home-manager switch --flake $config_dir#<config-name>"
    echo ""

    if [[ "$platform" == "wsl" ]]; then
        echo "WSL-specific notes:"
        echo "  - Docker should be installed on Windows with WSL integration"
        echo "  - Use 'wslview' to open files in Windows"
        echo ""
    fi
}

# Print usage
print_usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Bootstrap installer for Nix + Home Manager development environment."
    echo ""
    echo "Options:"
    echo "  --skip-nix       Skip Nix installation"
    echo "  --skip-apply     Skip Home Manager configuration apply"
    echo "  --skip-clone     Skip cloning repository (use current directory)"
    echo "  --dir <path>     Installation directory (default: $INSTALL_DIR)"
    echo "  --help, -h       Show this help message"
    echo ""
    echo "Remote installation:"
    echo "  curl -fsSL https://raw.githubusercontent.com/uniaevum/initial-setup-automation/main/install.sh | bash"
    echo ""
    echo "With options:"
    echo "  curl -fsSL https://raw.githubusercontent.com/uniaevum/initial-setup-automation/main/install.sh | bash -s -- --skip-nix"
}

# Main function
main() {
    echo "=========================================="
    echo "  Nix + Home Manager Bootstrap Installer"
    echo "=========================================="
    echo ""

    local platform
    local arch
    platform=$(detect_platform)
    arch=$(detect_arch)

    log_info "Detected platform: $platform"
    log_info "Detected architecture: $arch"

    if [[ "$platform" == "unknown" ]]; then
        log_error "Unknown platform. This script supports Linux, macOS, and WSL."
        exit 1
    fi

    if [[ "$arch" == "unknown" ]]; then
        log_error "Unknown architecture. This script supports x86_64 and aarch64."
        exit 1
    fi

    # Parse arguments
    local skip_nix=false
    local skip_apply=false
    local skip_clone=false
    local config_dir="$INSTALL_DIR"

    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-nix)
                skip_nix=true
                shift
                ;;
            --skip-apply)
                skip_apply=true
                shift
                ;;
            --skip-clone)
                skip_clone=true
                shift
                ;;
            --dir)
                config_dir="$2"
                shift 2
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

    # Check SSH key (needed for mise/pyenv to clone from GitHub)
    check_ssh_key

    # Install Nix
    if [[ "$skip_nix" == "false" ]]; then
        install_nix
    else
        log_warn "Skipping Nix installation"
        # Still try to source nix if it exists
        source_nix
    fi

    # Setup flake
    setup_flake

    # Clone repository (for remote execution)
    if [[ "$skip_clone" == "false" ]]; then
        setup_repo "$config_dir"
    else
        # Use current directory or specified directory
        if [[ "$config_dir" == "$INSTALL_DIR" ]]; then
            # Check if we're in a directory with flake.nix
            if [[ -f "./flake.nix" ]]; then
                config_dir="$(pwd)"
                log_info "Using current directory: $config_dir"
            else
                log_error "No flake.nix found in current directory. Remove --skip-clone or run from repository root."
                exit 1
            fi
        fi
        # Configure username even when skipping clone
        configure_username "$config_dir"
    fi

    # Apply Home Manager configuration
    if [[ "$skip_apply" == "false" ]]; then
        apply_home_manager "$config_dir" "$platform" "$arch"
    else
        log_warn "Skipping Home Manager configuration apply"
    fi

    # Post-installation
    post_install

    # Print next steps
    print_next_steps "$platform" "$config_dir"
}

main "$@"
