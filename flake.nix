{
  description = "A convention-based extensible configuration framework for Nix flake.";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = inputs:
    let
      lib = import ./nix/lib/conflake.nix inputs;
    in
    lib.mkOutputs ./. inputs {
      outputs = {
        __functor = _: lib.mkOutputs;
      };
    };
}
