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
    nixosModule = mkOption {
      type = types.unspecified;
      default = null;
    };

    nixosModules = mkOption {
      type = types.unspecified;
      default = { };
    };
  };

  config = {
    final =
      { config, ... }:
      {
        options = {
          nixosModule = mkOption {
            type = nullable deferredModule;
            default = null;
          };

          nixosModules = mkOption {
            type = optCallWith moduleArgs (lazyAttrsOf deferredModule);
            default = { };
          };
        };

        config = mkMerge [
          { inherit (rootConfig) nixosModule nixosModules; }

          (mkIf (config.nixosModule != null) {
            nixosModules.default = config.nixosModule;
          })

          (mkIf (config.nixosModules != { }) {
            outputs = {
              inherit (config) nixosModules;
            };
          })
        ];
      };

    loaders = config.nixDir.mkModuleLoader "nixosModules";
  };
}
