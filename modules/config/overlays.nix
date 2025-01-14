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
    types
    ;
  inherit (lib.types) lazyAttrsOf;
  inherit (conflake.types) nullable optCallWith overlay;

  rootConfig = config;
in
{
  options = {
    overlay = mkOption {
      type = types.anything;
      default = null;
    };

    overlays = mkOption {
      type = types.anything;
      default = { };
    };
  };

  config.final =
    { config, ... }:
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
        { inherit (rootConfig) overlay overlays; }

        (mkIf (config.overlay != null) {
          overlays.default = config.overlay;
        })

        (mkIf (config.overlays != { }) {
          outputs = {
            inherit (config) overlays;
          };
        })
      ];
    };
}
