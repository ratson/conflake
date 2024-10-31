{ config, lib, conflake, ... }:

let
  inherit (lib) mkMerge mkOption mkIf types;
in
{
  options = {
    overlay = mkOption {
      type = types.nullOr conflake.types.overlay;
      default = null;
    };

    overlays = mkOption {
      type = types.lazyAttrsOf conflake.types.overlay;
      default = { };
    };
  };

  config = mkMerge [
    (mkIf (config.overlay != null) {
      overlays.default = config.overlay;
    })

    (mkIf (config.overlays != { }) {
      outputs = { inherit (config) overlays; };
    })
  ];
}
