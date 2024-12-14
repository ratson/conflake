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

      presets.checks.deadnix = {
        enable = true;
        files = [
          "misc"
          "modules"
          "nix"
        ];
      };
    };

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
}
