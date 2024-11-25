{
  outputs =
    { conflake, ... }@inputs:
    conflake ./. {
      inherit inputs;

      packages.hi = { pkgs, ... }: pkgs.hello;

      perSystem =
        { pkgs, ... }:
        {
          packages.haloha = pkgs.hello;
        };
    };

  inputs = {
    conflake = {
      url = "../..";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };
}
