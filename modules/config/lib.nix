{
  config,
  lib,
  conflake,
  moduleArgs,
  ...
}:

let
  inherit (lib)
    hasSuffix
    isFunction
    mkMerge
    mkOption
    mkIf
    nameValuePair
    removeSuffix
    types
    ;
  inherit (lib.types) lazyAttrsOf;
  inherit (conflake.types) optCallWith;

  cfg = config.lib;
in
{
  options.lib = mkOption {
    type = conflake.types.loadable;
    default = { };
  };

  config = {
    final =
      { config, ... }:
      {
        options.lib = mkOption {
          type = optCallWith moduleArgs (lazyAttrsOf types.raw);
          default = { };
        };

        config = mkMerge [
          { lib = cfg; }

          (mkIf (config.lib != { }) {
            outputs.lib = config.lib;
          })
        ];
      };

    nixDir.loaders.lib = {
      collect =
        { dir, ignore, ... }:
        conflake.collectPaths {
          inherit dir ignore;
        };
      load =
        { src, dirTree, ... }:
        {
          lib = config.loadDirTree {
            inherit dirTree;
            dir = src;
            mkFilePair =
              k: v:
              let
                value = import v;
                value' = if isFunction value then value moduleArgs else value;
              in
              if hasSuffix ".raw.nix" k then
                nameValuePair (removeSuffix ".raw.nix" k) value
              else
                nameValuePair (removeSuffix ".nix" k) value';
          };
        };
    };
  };
}
