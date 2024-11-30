{
  config,
  options,
  lib,
  conflake,
  moduleArgs,
  ...
}:

let
  inherit (builtins) elem;
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
          inherit (options)
            darwinModules
            homeModules
            nixosModules
            templates
            ;

          checks = mkOption {
            type = lazyAttrsOf (lazyAttrsOf lib.types.package);
            default = { };
          };
        };
      };
      apply = filterAttrs (
        k: v:
        !(
          elem k [
            "checks"
            "darwinModules"
            "homeModules"
            "nixosModules"
            "templates"
          ]
          && v == { }
        )
      );
    };
  };

  config.finalOutputs = mkMerge [
    config.loadedOutputs
    config.outputs
  ];
}
