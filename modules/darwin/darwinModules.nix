{
  config,
  lib,
  conflake,
  moduleArgs,
  ...
}:

let
  inherit (lib) mkOption mkIf mkMerge;
  inherit (lib.types) lazyAttrsOf deferredModule;
  inherit (conflake.types) nullable optCallWith;
in
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
    (mkIf (config.darwinModule != null) {
      darwinModules.default = config.darwinModule;
    })
    (mkIf (config.darwinModules != { }) {
      outputs = {
        inherit (config) darwinModules;
      };
    })
    {
      loaders = config.nixDir.mkModuleLoader "darwinModules";
    }
  ];
}
