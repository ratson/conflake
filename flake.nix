{
  description = "A batteries included, convention-based configuration framework for Nix Flakes.";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = inputs:
    let
      lib = import ./nix/lib/conflake.nix inputs;
    in
    lib.mkOutputs ./. inputs {
      functor = _: lib.mkOutputs;

      outputs = {
        tests = import ./tests inputs;
      };
    };
}
