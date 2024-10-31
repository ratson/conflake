{ config, lib, ... }:

let
  inherit (lib) mapAttrs mkOption mkIf mkMerge types;
in
{
  options = {
    homeModule = mkOption {
      type = types.raw;
      default = null;
    };

    homeModules = mkOption {
      type = types.lazyAttrsOf types.raw;
      default = { };
    };
  };

  config = mkMerge [
    (mkIf (config.nixDirEntries ? homeModules) {
      homeModules = mapAttrs
        (_: homeModule: (_: {
          imports = [
            config.argsModule
            homeModule
          ];
        }))
        config.nixDirEntries.homeModules;
    })

    (mkIf (config.homeModule != null) {
      homeModules.default = config.homeModule;
    })

    (mkIf (config.homeModules != { }) {
      outputs = { inherit (config) homeModules; };
    })
  ];
}
