{
  config,
  options,
  lib,
  conflake,
  moduleArgs,
  ...
}:

let
  inherit (builtins) attrNames elem;
  inherit (lib) filterAttrs mkMerge mkOption;
  inherit (lib.types)
    lazyAttrsOf
    package
    raw
    submodule
    ;
  inherit (conflake.types) optCallWith outputs;

  outputsOptions = {
    inherit (options)
      darwinModules
      homeModules
      nixosModules
      templates
      ;

    checks = mkOption {
      type = lazyAttrsOf (lazyAttrsOf package);
      default = { };
    };

    outputs = mkOption {
      type = lazyAttrsOf raw;
      default = { };
    };

    packages = mkOption {
      type = lazyAttrsOf (lazyAttrsOf package);
      default = { };
    };
  };
in
{
  options = {
    outputs = mkOption {
      type = optCallWith moduleArgs outputs;
      default = { };
    };

    finalOutputs = mkOption {
      internal = true;
      readOnly = true;
      type = submodule {
        freeformType = lazyAttrsOf raw;
        options = outputsOptions;
      };
      apply = filterAttrs (k: v: !(elem k (attrNames outputsOptions) && v == { }));
    };
  };

  config.finalOutputs = mkMerge [
    config.loadedOutputs.outputs
    config.outputs
  ];
}
