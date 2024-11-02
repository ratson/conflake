inputs:

let
  inherit (builtins) all head isAttrs length mapAttrs;

  inherit (inputs.nixpkgs) lib;
  inherit (lib) composeManyExtensions evalModules getValues isFunction mkOptionType;
  inherit (lib.options) showDefs showOption;
  inherit (lib.types) lazyAttrsOf;

  baseModules = import ../../modules/module-list.nix;

  mkOutputs = {
    __functor = self: src: inputs: module: (evalModules {
      modules = baseModules ++ [
        { inherit inputs src; }
        module
      ];
      specialArgs = { inherit conflake; };
    }
    ).config.outputs;
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
          throw "The option `${showOption loc}' has conflicting definitions.\n\nDefinition values:${showDefs defs} \n";
    };

    outputs = lazyAttrsOf outputsValue;

    overlay = mkOptionType {
      name = "overlay";
      description = "nixpkgs overlay";
      descriptionClass = "noun";
      check = isFunction;
      merge = _: defs: composeManyExtensions (getValues defs);
    };
  };

  conflake = {
    inherit mkOutputs selectAttr types;
  };
in
conflake
