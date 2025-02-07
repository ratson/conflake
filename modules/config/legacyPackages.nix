{
  config,
  lib,
  conflake,
  ...
}:

let
  inherit (lib)
    mkIf
    mkMerge
    mkOption
    pipe
    ;
  inherit (conflake.loaders) loadDirWithDefault;
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
        { pkgsCall }:
        loadDirWithDefault {
          root = path;
          tree = node;
          load = pkgsCall;
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
