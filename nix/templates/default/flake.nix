{
  description = "Description for the project";

  outputs =
    { conflake, ... }@inputs:
    conflake ./. {
      inherit inputs;

      devShell.packages = { pkgs }: with pkgs; [ hello ];
    };

  inputs = {
    conflake = {
      url = "github:ratson/conflake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
}
