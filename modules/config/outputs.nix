{
  config,
  options,
  lib,
  conflake,
  moduleArgs,
  ...
}:

let
  inherit (lib) filterAttrs mkMerge mkOption;
  inherit (lib.types) lazyAttrsOf raw submodule;
  inherit (conflake.types) optCallWith outputs;
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
        options = {
          inherit (options) templates;
        };
      };
      apply = filterAttrs (k: v: !(k == "templates" && v == { }));
    };
  };

  config.finalOutputs = mkMerge [
    config.loadedOutputs
    config.outputs
  ];
}
