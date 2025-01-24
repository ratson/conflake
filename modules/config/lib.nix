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
in
{
  options.lib = mkOption {
    type = optCallWith moduleArgs (lazyAttrsOf types.raw);
    default = { };
  };

  config = mkMerge [
    (mkIf (config.lib != { }) {
      outputs.lib = config.lib;
    })

    {
      nixDir.loaders.lib =
        { node, path, ... }:
        conflake'.loadDir' {
          root = path;
          tree = node;
          mkFilePair =
            { name, node, ... }:
            let
              value = import node;
              value' = if isFunction value then value moduleArgs else value;
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
