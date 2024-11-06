{
  description = "A batteries included, convention-based configuration framework for Nix Flakes.";

  outputs = inputs:
    let
      lib = import ./. inputs;
    in
    lib.mkOutputs ./. {
      inherit lib;

      checks.statix = pkgs: "${pkgs.statix}/bin/statix check";

      functor = _: lib.mkOutputs;

      outputs.tests = import ./tests/run.nix inputs;

      templates = {
        default = {
          path = ./templates/default;
          description = "Minimal Conflake flake.";
        };
      };
    };

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
}
