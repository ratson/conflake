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
    pipe
    types
    ;
  inherit (lib.types) lazyAttrsOf;
  inherit (conflake) callWith;
  inherit (conflake.loaders) loadDir';
  inherit (conflake.types) optCallWith;

  cfg = config.lib;
in
{
  options.lib = mkOption {
    type = optCallWith moduleArgs (lazyAttrsOf types.raw);
    default = { };
  };

  config = mkMerge [
    (mkIf (cfg != { }) {
      outputs.lib = cfg;
    })

    {
      nixDir.loaders.lib =
        { node, path, ... }:
        loadDir' {
          root = path;
          tree = node;
          mkFilePair =
            { name, node, ... }:
            let
              value = import node;
              value' = if isFunction value then pipe value [ (callWith moduleArgs) ] else value;
            in
            if hasSuffix ".raw.nix" name then
              nameValuePair (removeSuffix ".raw.nix" name) value
            else
              nameValuePair (removeSuffix ".nix" name) value';
        };

      nixDir.matchers.lib = conflake.matchers.always;
    }
  ];
}
