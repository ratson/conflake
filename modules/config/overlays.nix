{
  config,
  lib,
  conflake,
  moduleArgs,
  ...
}:

let
  inherit (lib)
    mkIf
    mkMerge
    mkOption
    ;
  inherit (lib.types) lazyAttrsOf;
  inherit (conflake.types) nullable optCallWith overlay;

  cfg = config.overlays;
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

    (mkIf (cfg != { }) {
      outputs.overlays = cfg;
    })
  ];
}
