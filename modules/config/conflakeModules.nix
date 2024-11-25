{
  config,
  lib,
  conflake,
  moduleArgs,
  ...
}:

let
  inherit (lib) mkOption mkIf mkMerge;
  inherit (lib.types) lazyAttrsOf;
  inherit (conflake.types) module nullable optCallWith;
in
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
    (mkIf (config.conflakeModule != null) {
      conflakeModules.default = config.conflakeModule;
    })

    (mkIf (config.conflakeModules != { }) {
      outputs = {
        inherit (config) conflakeModules;
      };
    })
  ];
}
