{ config, lib, conflake, moduleArgs, ... }:

let
  inherit (lib) mkMerge mkOption mkIf;
  inherit (lib.types) lazyAttrsOf;
  inherit (conflake.types) nullable optCallWith overlay;
in
{
  options = {
    overlay = mkOption {
      type = nullable overlay;
      default = null;
    };

    overlays = mkOption {
      type = optCallWith moduleArgs (lazyAttrsOf overlay);
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
