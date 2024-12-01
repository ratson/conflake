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
  inherit (lib.types)
    lazyAttrsOf
    package
    raw
    submodule
    ;
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
            type = lazyAttrsOf (lazyAttrsOf package);
            default = { };
          };

          packages = mkOption {
            type = lazyAttrsOf (lazyAttrsOf package);
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
            "packages"
            "templates"
          ]
          && v == { }
        )
      );
    };
  };

  config.finalOutputs = mkMerge [
    (filterAttrs (k: _: !(elem k [ "packages" ])) config.loadedOutputs)
    config.outputs
  ];
}
