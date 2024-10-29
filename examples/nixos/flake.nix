{
  inputs.conflake = {
    url = "../..";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  inputs.greet = {
    url = "../named-package";
    inputs.conflake.follows = "conflake";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { conflake, ... }@inputs:
    conflake ./. inputs {
      outputs = {
        nixosConfigurations.vm2 = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";

          modules = [
            inputs.self.nixosModules.default
            { system.stateVersion = "24.11"; }
          ];
        };
      };

    };
}
