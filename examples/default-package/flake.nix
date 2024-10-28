{
  inputs.conflake = {
    url = "../..";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { conflake, ... }@inputs:
    conflake ./. inputs { };
}
