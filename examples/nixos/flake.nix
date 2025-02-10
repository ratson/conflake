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

      nixpkgs.overlays = [
        inputs.overlay.overlays.default
        (final: _: {
          broken = final.lib.trace "fix broken package" final.hello;
          broken-here = final.lib.trace "fix broken-here package" final.hello;
        })
      ];

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
              home-manager = {
                sharedModules = [
                  inputs.overlay.homeModules.default
                  self.homeModules.default
                  self.homeModules.greet
                ];

                users.root = {
                  programs.fish.enable = true;

                  home.stateVersion = "24.11";
                };
              };

              nixpkgs.overlays = [
                (final: _: {
                  broken = final.lib.trace "fix broken package (config)" final.hello;
                  broken-here = final.lib.trace "fix broken-here package (config)" final.hello;
                })
              ];

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
    demo = {
      url = "../demo";
      inputs = {
        conflake.follows = "conflake";
        home-manager.follows = "home-manager";
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };
    greet = {
      url = "../packages";
      inputs.conflake.follows = "conflake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    overlay = {
      url = "../overlay";
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
