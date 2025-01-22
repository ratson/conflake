{
  config,
  lib,
  conflake,
  moduleArgs,
  ...
}:

let
  inherit (lib)
    mkOption
    mkIf
    mkMerge
    types
    ;
  inherit (lib.types) lazyAttrsOf;
  inherit (conflake.types) module nullable optCallWith;

  rootConfig = config;
in
{
  options = {
    conflakeModule = mkOption {
      type = types.unspecified;
      default = null;
    };

    conflakeModules = mkOption {
      type = conflake.types.loadable;
      default = { };
    };
  };

  config.final =
    { config, ... }:
    {
      options = {
        conflakeModule = mkOption {
          type = nullable module;
          default = null;
        };

        conflakeModules = mkOption {
          type = optCallWith moduleArgs (lazyAttrsOf module);
          default = { };
        };
      };

      config = mkMerge [
        { inherit (rootConfig) conflakeModule conflakeModules; }

        (mkIf (config.conflakeModule != null) {
          conflakeModules.default = config.conflakeModule;
        })

        (mkIf (config.conflakeModules != { }) {
          outputs = {
            inherit (config) conflakeModules;
          };
        })
      ];
    };
}
