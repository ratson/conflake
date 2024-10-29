inputs:

let
  inherit (builtins) all head isAttrs length;

  inherit (inputs.nixpkgs) lib;

  inherit (lib) evalModules getValues mapAttrs mkOptionType;
  inherit (lib.options) mergeDefaultOption;
  inherit (lib.types) lazyAttrsOf;

  baseModules = import ../../modules/module-list.nix;

  mkOutputs = {
    __functor = self: src: inputs: module: (evalModules {
      modules = baseModules ++ [
        {
          inherit inputs src;

          _module.args = { inherit conflake; };
        }
        module
      ];
    }).config.finalOutputs;
  };

  selectAttr = attr: mapAttrs (_: v: v.${attr} or { });

  types = rec {
    outputsValue = mkOptionType {
      name = "outputs";
      description = "outputs value";
      descriptionClass = "noun";
      merge = loc: defs:
        if (length defs) == 1 then
          (head defs).value
        else if all isAttrs (getValues defs) then
          (lazyAttrsOf outputsValue).merge loc defs
        else
          mergeDefaultOption loc defs;
    };

    outputs = lazyAttrsOf outputsValue;
  };

  conflake = {
    inherit mkOutputs selectAttr types;
  };
in
conflake
