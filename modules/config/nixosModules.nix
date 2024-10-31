{ config, lib, ... }:

{
  options = {
    nixosModule = lib.mkOption {
      type = lib.types.raw;
      default = null;
    };

    nixosModules = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.raw;
      apply = modules: builtins.mapAttrs
        (_: module: (_: {
          imports = [
            config.argsModule
            module
          ];
        }))
        modules;
      default = { };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (config.nixDirEntries ? nixosModules) {
      nixosModules = config.nixDirEntries.nixosModules;
    })

    (lib.mkIf (config.nixosModule != null) {
      nixosModules.default = config.nixosModule;
    })

    (lib.mkIf (config.nixosModules != { }) {
      outputs = { inherit (config) nixosModules; };
    })
  ];
}
