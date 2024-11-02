{
  description = "A batteries included, convention-based configuration framework for Nix Flakes.";

  outputs = inputs:
    let
      lib = import ./. inputs;
    in
    lib.mkFlake ./. {
      inherit lib;

      checks.statix = pkgs: "${pkgs.statix}/bin/statix check";

      functor = _: lib.mkFlake;

      outputs.tests = import ./tests inputs;

      templates = {
        default = {
          path = ./default;
          description = "Minimal Conflake flake.";
        };
      };
    };

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
}
