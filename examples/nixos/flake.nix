{
  inputs.conflake = {
    url = "../..";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { conflake, ... }@inputs:
    conflake ./. inputs {
      outputs = {
        nixosConfigurations.vm2 = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";

          modules = [
            { system.stateVersion = "24.11"; }
          ];
        };
      };

    };
}
