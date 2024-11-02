{ config, lib, conflake, moduleArgs, ... }:

let
  inherit (builtins) mapAttrs;
  inherit (lib) mkOption mkIf mkMerge;
  inherit (lib.types) lazyAttrsOf;
  inherit (conflake.types) module nullable optCallWith;
in
{
  options = {
    homeModule = mkOption {
      type = nullable module;
      default = null;
    };

    homeModules = mkOption {
      type = optCallWith moduleArgs (lazyAttrsOf module);
      apply = mapAttrs (_: module: {
        imports = [
          config.argsModule
          module
        ];
      });
      default = { };
    };
  };

  config = mkMerge [
    (mkIf (config.homeModule != null) {
      homeModules.default = config.homeModule;
    })

    (mkIf (config.homeModules != { }) {
      outputs = { inherit (config) homeModules; };
    })
  ];
}
