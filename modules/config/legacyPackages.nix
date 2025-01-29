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
  inherit (lib.types) functionTo;
  inherit (config) genSystems;
  inherit (conflake.types) nullable;
in
{
  options.legacyPackages = mkOption {
    type = nullable (functionTo conflake.types.legacyPackages);
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
