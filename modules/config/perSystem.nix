{ config, lib, conflake, pkgsFor, ... }:

let
  inherit (builtins) mapAttrs;
  inherit (lib) foldAttrs mergeAttrs mkOption;
  inherit (lib.types) functionTo;
  inherit (conflake.types) outputs;
in
{
  options = {
    perSystem = mkOption {
      type = functionTo outputs;
      default = _: { };
    };
  };

  config = {
    outputs = foldAttrs mergeAttrs { } (map
      (system: mapAttrs
        (_: v: { ${system} = v; })
        (config.perSystem pkgsFor.${system}))
      config.systems);
  };
}
