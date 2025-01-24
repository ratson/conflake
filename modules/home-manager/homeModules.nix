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
    (mkIf (config.homeModules != { }) {
      outputs = {
        inherit (config) homeModules;
      };
    })
    {
      nixDir.loaders.homeModules = config.loaderForModule;
    }
  ];
}
