{
  config,
  lib,
  conflake,
  moduleArgs,
  ...
}:

let
  inherit (lib)
    flip
    mkIf
    mkMerge
    mkOption
    types
    ;
  inherit (lib.types) functionTo lazyAttrsOf;
  inherit (conflake.types) nullable;

  cfg = config.legacyPackages;
in
{
  options.legacyPackages = mkOption {
    type = types.unspecified;
    default = null;
  };

  config = {
    final =
      { config, ... }:
      {
        options.legacyPackages = mkOption {
          type = nullable (functionTo (lazyAttrsOf types.unspecified));
          default = null;
        };

        config = mkMerge [
          { legacyPackages = cfg; }

          (mkIf (config.legacyPackages != null) {
            outputs.legacyPackages = config.genSystems config.legacyPackages;
          })
        ];
      };

    loaders = config.nixDir.mkLoader' "legacyPackages" {
      collect =
        { dir, ignore, ... }:
        conflake.collectPaths {
          inherit dir ignore;
        };
      load =
        { src, dirTree, ... }:
        {
          legacyPackages =
            pkgs:
            config.loadDirTreeWithDefault {
              inherit dirTree;
              dir = src;
              load = flip pkgs.callPackage moduleArgs;
            };
        };
    };
  };
}
