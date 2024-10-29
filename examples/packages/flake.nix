{
  inputs.conflake = {
    url = "../..";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { conflake, ... }@inputs:
    conflake ./. inputs {
      packages.hi = { pkgs, ... }: pkgs.hello;

      perSystem = { pkgs, ... }: {
        packages.haloha = pkgs.hello;

        devShells.default = pkgs.mkShell {
          packages = [ inputs.self.packages.${pkgs.system}.greet ];
        };
      };
    };
}
