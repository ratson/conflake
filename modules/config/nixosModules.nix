{ config, lib, conflake, moduleArgs, ... }:

let
  inherit (lib) mkOption mkIf mkMerge;
  inherit (lib.types) lazyAttrsOf deferredModule;
  inherit (conflake.types) nullable optCallWith;
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
    (mkIf (config.nixDir.entries ? nixosModules) {
      nixosModules = conflake.loadModules
        config.nixDir.entries.nixosModules
        moduleArgs;
    })

    (mkIf (config.nixosModule != null) {
      nixosModules.default = config.nixosModule;
    })

    (mkIf (config.nixosModules != { }) {
      outputs = { inherit (config) nixosModules; };
    })
  ];
}
