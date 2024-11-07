{
  outputs = { conflake, self, nix-darwin, nixpkgs, ... }@inputs:
    conflake ./. {
      inherit inputs;
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
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };
}
