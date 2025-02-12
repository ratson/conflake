{
  outputs =
    { conflake, self, ... }@inputs:
    conflake ./. {
      inherit inputs;

      _module.args = {
        extra-arg = true;
      };

      devShell.packages =
        { pkgs, system }:
        [
          pkgs.hello
          self.packages.${system}.default
        ];

      packages.hi = pkgs: pkgs.hello;

      perSystem =
        { pkgs }:
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
