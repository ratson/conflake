inputs:

let
  inherit (inputs.nixpkgs.lib) evalModules;

  baseModules = import ../../modules/module-list.nix;

  mkOutputs = {
    __functor = self: src: inputs: module: (evalModules {
      modules = baseModules ++ [
        { inherit inputs src; }
        module
      ];
    }).config.finalOutputs;
  };
in
{
  inherit mkOutputs;
}
