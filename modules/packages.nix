{ config, pkgs, lib, isLinux, isDarwin, isWSL, ... }:

let
  # Common packages for all platforms
  commonPackages = with pkgs; [
    # Core utilities
    coreutils
    curl
    wget
    jq
    yq
    tree
    htop
    ripgrep
    fd
    bat
    eza
    delta
    ncdu
    unzip
    zip
    gnupg

    # Development tools
    vim
    git
    gh
    pre-commit
    shellcheck
    shfmt

    # Network tools
    # openssh is excluded to use system SSH (avoids /etc/ssh/ssh_config compatibility issues)
    nmap
    dnsutils

    # File tools
    file
    less

    # Process tools
    procps
    psmisc

    # Claude CLI - installed via npm/npx approach
    # Note: Claude CLI is best installed via: npm install -g @anthropic-ai/claude-code

    # Nix tools
    nil
    nixpkgs-fmt
    nix-tree
    nix-diff
  ];

  # Linux-specific packages
  linuxPackages = with pkgs; [
    # System monitoring
    iotop
    sysstat
    strace
    ltrace

    # Networking
    iproute2
    iptables
  ];

  # macOS-specific packages (installed via Home Manager, not Homebrew)
  darwinPackages = with pkgs; [
    # macOS doesn't need most system tools as they're built-in
    coreutils-prefixed
  ];

  # WSL-specific packages
  wslPackages = with pkgs; [
    # WSL utilities
    wslu
  ];

in
{
  home.packages = commonPackages
    ++ lib.optionals isLinux linuxPackages
    ++ lib.optionals isDarwin darwinPackages
    ++ lib.optionals isWSL wslPackages;

  # Claude CLI installation script
  # Claude Code is distributed via npm, so we create a helper script
  home.file.".local/bin/install-claude".source = pkgs.writeShellScript "install-claude" ''
    #!/usr/bin/env bash
    set -euo pipefail

    echo "Installing Claude CLI (Claude Code)..."

    # Check if npm is available (should be via mise)
    if ! command -v npm &> /dev/null; then
      echo "npm not found. Please run 'mise install node' first."
      exit 1
    fi

    # Install Claude Code globally
    npm install -g @anthropic-ai/claude-code

    echo ""
    echo "Claude CLI installed successfully!"
    echo "Run 'claude' to start using it."
    echo ""
    echo "To authenticate, run: claude auth"
  '';

}
