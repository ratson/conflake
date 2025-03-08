{
  outputs =
    { conflake, self, ... }@inputs:
    conflake ./. {
      inherit inputs;

      nixDir = {
        src = ./.;
        aliases = {
          "packages" = "pkgs";
        };
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
