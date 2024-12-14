{
  description = "A batteries included, convention-based configuration framework for Nix Flakes.";

  outputs =
    inputs:
    let
      lib = import ./. inputs;
    in
    lib.mkOutputs ./. {
      inherit inputs lib;

      functor = _: lib.mkOutputs;

      templates = {
        default = {
          description = "Minimal Conflake flake.";
        };
      };

      outputs.tests = import ./tests/run.nix inputs;
      presets.checks.deadnix = {
        enable = true;
        exclude = "nix/tests";
        files = [
          "misc"
          "modules"
          "nix"
        ];
      };
    };

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
}
