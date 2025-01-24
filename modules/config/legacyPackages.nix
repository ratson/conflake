{
  config,
  lib,
  conflake,
  conflake',
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
      nixDir.loaders.legacyPackages =
        { node, path, ... }:
        pkgs:
        conflake'.loadDirWithDefault {
          root = path;
          tree = node;
          load = flip pkgs.callPackage moduleArgs;
        };

      nixDir.matchers.legacyPackages = conflake.matchers.always;
    }
  ];
}
