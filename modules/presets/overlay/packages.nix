{ config, lib, ... }:

let
  inherit (lib)
    flip
    mkEnableOption
    mkIf
    pipe
    ;

  cfg = config.presets.overlay.packages;
in
{
  options.presets.overlay.packages = mkEnableOption "packages overlay" // {
    default = config.presets.overlay.enable;
  };

  config.final =
    { config, ... }:
    {
      config = mkIf (cfg && config.packages != null) {
        overlay =
          final:
          flip pipe [
            (config.packageOverlay (final.appendOverlays config.withOverlays))
            (flip removeAttrs [ "default" ])
          ];
      };
    };
}
