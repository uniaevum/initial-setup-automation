{ config, pkgs, lib, ... }:

{
  # Install mise via Home Manager
  home.packages = with pkgs; [
    mise
  ];

  # mise configuration file
  xdg.configFile."mise/config.toml".text = ''
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
    # Core development tools managed by mise

    # Container tools
    "docker-compose" = "latest"

    # Programming languages
    rust = "latest"
    node = "22"
    python = "latest"

    # Infrastructure as Code
    terraform = "latest"

    # Kubernetes tools
    kubectl = "latest"
    helm = "latest"
    helmfile = "latest"

    # Version aliases (new format)
    [alias.node.versions]
    lts = "22"
  '';

  # mise settings for shell integration are handled in shell.nix

  # Create a helper script for mise setup
  home.file.".local/bin/mise-setup".source = pkgs.writeShellScript "mise-setup" ''
    #!/usr/bin/env bash
    set -euo pipefail

    echo "Setting up mise tools..."

    # Trust the global config
    mise trust ~/.config/mise/config.toml

    # Install all configured tools
    mise install

    echo "mise setup complete!"
    echo ""
    echo "Installed tools:"
    mise list
  '';
}
