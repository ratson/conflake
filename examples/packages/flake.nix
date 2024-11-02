{
  inputs.conflake = {
    url = "../..";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { conflake, ... }@inputs:
    conflake ./. {
      inherit inputs;

      packages.hi = { pkgs, ... }: pkgs.hello;

      perSystem = { pkgs, ... }: {
        packages.haloha = pkgs.hello;
      };
    };
}
