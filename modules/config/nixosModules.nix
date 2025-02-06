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

  cfg = config.nixosModules;
in
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
    (mkIf (config.nixosModule != null) {
      nixosModules.default = config.nixosModule;
    })
    (mkIf (cfg != { }) {
      outputs.nixosModules = cfg;
    })
    {
      nixDir.loaders.nixosModules = config.loaderForModule;
    }
  ];
}
