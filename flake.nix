{
  description = "My macOS system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    darwin.url = "github:LnL7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    mac-app-util.url = "github:hraban/mac-app-util";
    mac-app-util.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, darwin, home-manager, ... }@inputs:
    let
      system = "aarch64-darwin";
    in {
      darwinConfigurations."darwin-system" = darwin.lib.darwinSystem {
        inherit system;
        modules = [
          ./darwin-configuration.nix
        ];
        specialArgs = { inherit inputs; };
      };

      # Replace "username" with your actual username when using this configuration
      homeConfigurations."<username>" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { system = "aarch64-darwin"; };
        extraSpecialArgs = inputs;
        modules = [ ./home.nix ];
      };
    };
}

