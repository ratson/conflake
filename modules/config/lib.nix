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
    type = optCallWith moduleArgs (lazyAttrsOf types.unspecified);
    default = { };
  };

  config = mkMerge [
    (mkIf (config.lib != { }) {
      outputs.lib = config.lib;
    })

    {
      loaders = config.nixDir.mkLoader "lib" (
        { src, ... }:
        {
          lib = config.loadDir' (
            x:
            if hasSuffix ".fn.nix" x.name then
              nameValuePair (removeSuffix ".fn.nix" x.name) (import x.value moduleArgs)
            else
              nameValuePair (removeSuffix ".nix" x.name) (import x.value)
          ) src;
        }
      );
    }
  ];
}
