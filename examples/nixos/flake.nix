{
  outputs =
    {
      conflake,
      home-manager,
      nixpkgs,
      self,
      ...
    }@inputs:
    conflake ./. {
      inherit inputs;

      nixosModules.hi = {
        imports = [ self.nixosModules.greet ];
      };

      outputs = {
        nixosConfigurations.vm2 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";

          modules = [
            self.nixosModules.default
            self.nixosModules.greet
            home-manager.nixosModules.home-manager
            {
              home-manager.sharedModules = [
                self.homeModules.default
                self.homeModules.greet
              ];

              home-manager.users.root = {
                programs.fish.enable = true;

                home.stateVersion = "24.11";
              };
              system.stateVersion = "24.11";
            }
          ];
        };
      };
    };

  inputs = {
    conflake = {
      url = "../..";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    greet = {
      url = "../packages";
      inputs.conflake.follows = "conflake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default-linux";
  };
}
