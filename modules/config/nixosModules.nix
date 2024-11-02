{ config, lib, conflake, moduleArgs, ... }:

let
  inherit (builtins) mapAttrs;
  inherit (lib) mkOption mkIf mkMerge;
  inherit (lib.types) lazyAttrsOf;
  inherit (conflake.types) module nullable optCallWith;
in
{
  options = {
    nixosModule = mkOption {
      type = nullable module;
      default = null;
    };

    nixosModules = mkOption {
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
    (mkIf (config.nixosModule != null) {
      nixosModules.default = config.nixosModule;
    })

    (mkIf (config.nixosModules != { }) {
      outputs = { inherit (config) nixosModules; };
    })
  ];
}
