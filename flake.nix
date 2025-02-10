{
  description = "A batteries included, convention-based configuration framework for Nix Flakes.";

  outputs =
    inputs:
    let
      lib = import ./. inputs;
      conflake = lib.mkOutputs;
    in
    conflake ./. {
      inherit inputs lib;

      functor = _: conflake;

      presets.enable = false;
    };

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
}
