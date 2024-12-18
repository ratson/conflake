{
  config,
  lib,
  conflake,
  genSystems,
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
in
{
  options.legacyPackages = mkOption {
    type = nullable (functionTo (lazyAttrsOf types.unspecified));
    default = null;
  };

  config = mkMerge [
    (mkIf (config.legacyPackages != null) {
      outputs.legacyPackages = genSystems config.legacyPackages;
    })

    {
      loaders = config.nixDir.mkLoader "legacyPackages" (
        { src, ... }:
        {
          legacyPackages =
            pkgs:
            config.loadDirWithDefault {
              root = src;
              load = flip pkgs.callPackage moduleArgs;
            };
        }
      );
    }
  ];
}
