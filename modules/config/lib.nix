{ config, lib, ... }:

let
  inherit (lib) mapAttrs mkMerge mkOption mkIf types;
in
{
  options = {
    lib = mkOption {
      type = types.lazyAttrsOf types.raw;
      default = { };
    };
  };

  config = mkMerge [
    (mkIf (config.nixDirEntries ? lib) {
      lib = mapAttrs (_: v: import v)
        config.nixDirEntries.lib;
    })

    (mkIf (config.lib != { }) {
      outputs = {
        inherit (config) lib;
      };
    })
  ];
}
