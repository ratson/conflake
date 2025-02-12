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
  inherit (lib.types) either lazyAttrsOf raw;
  inherit (conflake.loaders) loadDirWithDefault;
  inherit (conflake.types) optFunctionTo nullable;

  cfg = config.legacyPackages;
in
{
  options.legacyPackages = mkOption {
    type = nullable (optFunctionTo (lazyAttrsOf (either (lazyAttrsOf raw) raw)));
    default = null;
  };

  config = mkMerge [
    (mkIf (cfg != null) {
      outputs.legacyPackages = config.genSystems ({ pkgsCall, ... }: pkgsCall cfg);
    })

    {
      nixDir.loaders.legacyPackages =
        { node, path, ... }:
        { pkgsCall, ... }:
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
