{ config, pkgs, lib, isLinux, isDarwin, isWSL, ... }:

{
  imports = [
    ./shell.nix
    ./git.nix
    ./mise.nix
    ./packages.nix
    # ./neovim.nix  # Uncomment when ready to add neovim config
  ];

  # Allow unfree packages (needed for some tools)
  nixpkgs.config.allowUnfree = true;

  # Enable Home Manager to manage itself
  programs.home-manager.enable = true;

  # Common home settings
  home = {
    # Environment variables
    sessionVariables = {
      EDITOR = "vim";
      VISUAL = "vim";
      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
    } // lib.optionalAttrs isWSL {
      # WSL-specific environment variables
      BROWSER = "wslview";
    };

    # Session path additions
    sessionPath = [
      "$HOME/.local/bin"
      "$HOME/.cargo/bin"
    ];
  };

  # XDG Base Directory specification
  xdg.enable = true;

  # SSH configuration
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    # Ignore system-wide ssh_config to avoid "Unsupported option" warnings
    # from Nix's newer OpenSSH not supporting Ubuntu's GSSAPI options
    extraConfig = ''
      IgnoreUnknown GSSAPIAuthentication,GSSAPIDelegateCredentials,GSSAPIKeyExchange,GSSAPITrustDNS
    '';

    matchBlocks = {
      # Default settings for all hosts
      "*" = {
        addKeysToAgent = "yes";
      };

      # GitHub configuration
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519";
        identitiesOnly = true;
      };
    };
  };
}
