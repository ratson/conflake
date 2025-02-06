{
  config,
  lib,
  conflake,
  conflake',
  moduleArgs,
  ...
}:

let
  inherit (lib)
    flip
    mkIf
    mkMerge
    mkOption
    pipe
    ;
  inherit (conflake.types) nullable;

  cfg = config.legacyPackages;
in
{
  options.legacyPackages = mkOption {
    type = nullable conflake.types.legacyPackages;
    default = null;
  };

  config = mkMerge [
    (mkIf (cfg != null) {
      outputs.legacyPackages = config.genSystems cfg;
    })

    {
      nixDir.loaders.legacyPackages =
        { node, path, ... }:
        { pkgs }:
        conflake'.loadDirWithDefault {
          root = path;
          tree = node;
          load = flip pkgs.callPackage moduleArgs;
          mkValue =
            { contexts, ... }:
            pipe contexts [
              (map (x: x.content.value))
              mkMerge
            ];
        };

      nixDir.matchers.legacyPackages = conflake.matchers.always;
    }
  ];
}
