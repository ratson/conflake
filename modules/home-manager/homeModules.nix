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
    homeModule = mkOption {
      type = types.unspecified;
      default = null;
    };

    homeModules = mkOption {
      type = types.unspecified;
      default = { };
    };
  };

  config = {
    final =
      { config, ... }:
      {
        options = {
          homeModule = mkOption {
            type = nullable deferredModule;
            default = null;
          };

          homeModules = mkOption {
            type = optCallWith moduleArgs (lazyAttrsOf deferredModule);
            default = { };
          };
        };

        config = mkMerge [
          { inherit (rootConfig) homeModule homeModules; }

          (mkIf (config.homeModule != null) {
            homeModules.default = config.homeModule;
          })
          (mkIf (config.homeModules != { }) {
            outputs = {
              inherit (config) homeModules;
            };
          })
        ];
      };

    loaders = config.nixDir.mkModuleLoader "homeModules";
  };
}
