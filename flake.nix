{
  description = "Cross-platform development environment with Nix and Home Manager";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Darwin support for macOS
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nix-darwin, ... }@inputs:
    let
      # Supported systems
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      # Helper function to generate attributes for each system
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Function to create home-manager configuration
      mkHomeConfig = { system, username, homeDirectory, extraModules ? [] }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          extraSpecialArgs = {
            inherit inputs system;
            isLinux = builtins.match ".*-linux" system != null;
            isDarwin = builtins.match ".*-darwin" system != null;
            isWSL = builtins.pathExists "/proc/sys/fs/binfmt_misc/WSLInterop" ||
                    builtins.getEnv "WSL_DISTRO_NAME" != "";
          };
          modules = [
            ./modules/home.nix
            {
              home = {
                inherit username homeDirectory;
                stateVersion = "24.05";
              };
            }
          ] ++ extraModules;
        };

      # __USERNAME__ will be replaced by install.sh with actual username
      username = "__USERNAME__";
    in
    {
      # Home Manager configurations
      homeConfigurations = {
        # Linux / WSL configuration (default)
        "${username}" = mkHomeConfig {
          system = "x86_64-linux";
          inherit username;
          homeDirectory = "/home/${username}";
        };

        # macOS (Intel) configuration
        "${username}-darwin-x86" = mkHomeConfig {
          system = "x86_64-darwin";
          inherit username;
          homeDirectory = "/Users/${username}";
        };

        # macOS (Apple Silicon) configuration
        "${username}-darwin-arm" = mkHomeConfig {
          system = "aarch64-darwin";
          inherit username;
          homeDirectory = "/Users/${username}";
        };

        # Linux ARM (e.g., Raspberry Pi, ARM servers)
        "${username}-linux-arm" = mkHomeConfig {
          system = "aarch64-linux";
          inherit username;
          homeDirectory = "/home/${username}";
        };
      };

      # Development shells for each system
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              nixpkgs-fmt
              nil
            ];
          };
        }
      );
    };
}
