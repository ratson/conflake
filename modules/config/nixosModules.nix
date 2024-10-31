{ config, lib, ... }:

let
  inherit (lib) mapAttrs mkIf mkMerge mkOption types;
in
{
  options = {
    nixosModule = mkOption {
      type = types.raw;
      default = null;
    };

    nixosModules = mkOption {
      type = types.lazyAttrsOf types.raw;
      default = { };
    };
  };

  config = mkMerge [
    (mkIf (config.nixDirEntries ? nixosModules) {
      nixosModules = mapAttrs
        (_: nixosModule: (_: {
          imports = [
            config.argsModule
            nixosModule
          ];
        }))
        config.nixDirEntries.nixosModules;
    })

    (mkIf (config.nixosModule != null) {
      nixosModules.default = config.nixosModule;
    })

    (mkIf (config.nixosModules != { }) {
      outputs = { inherit (config) nixosModules; };
    })
  ];
}
