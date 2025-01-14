{
  config,
  lib,
  conflake,
  moduleArgs,
  ...
}:

let
  inherit (lib)
    mkIf
    mkMerge
    mkOption
    types
    ;
  inherit (lib.types) lazyAttrsOf deferredModule;
  inherit (conflake.types) nullable optCallWith;

  rootConfig = config;
in
{
  options = {
    darwinModule = mkOption {
      type = types.unspecified;
      default = null;
    };

    darwinModules = mkOption {
      type = types.unspecified;
      default = { };
    };
  };

  config = {
    final =
      { config, ... }:
      {
        options = {
          darwinModule = mkOption {
            type = nullable deferredModule;
            default = null;
          };

          darwinModules = mkOption {
            type = optCallWith moduleArgs (lazyAttrsOf deferredModule);
            default = { };
          };
        };

        config = mkMerge [
          { inherit (rootConfig) darwinModule darwinModules; }

          (mkIf (config.darwinModule != null) {
            darwinModules.default = config.darwinModule;
          })
          (mkIf (config.darwinModules != { }) {
            outputs = {
              inherit (config) darwinModules;
            };
          })
        ];
      };

    loaders = config.nixDir.mkModuleLoader "darwinModules";
  };
}
