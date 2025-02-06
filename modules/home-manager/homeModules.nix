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
    ;
  inherit (lib.types) lazyAttrsOf deferredModule;
  inherit (conflake.types) nullable optCallWith;

  cfg = config.homeModules;
in
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
    (mkIf (config.homeModule != null) {
      homeModules.default = config.homeModule;
    })
    (mkIf (cfg != { }) {
      outputs.homeModules = cfg;
    })
    {
      nixDir.loaders.homeModules = config.loaderForModule;
    }
  ];
}
