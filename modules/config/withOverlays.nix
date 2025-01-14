{
  config,
  lib,
  conflake,
  ...
}:

let
  inherit (lib) mkOption types;
  inherit (conflake.types) optListOf overlay;

  cfg = config.withOverlays;
in
{
  options = {
    withOverlays = mkOption {
      type = types.unspecified;
      default = [ ];
    };
  };

  config.final = {
    options = {
      withOverlays = mkOption {
        type = optListOf overlay;
        default = [ ];
      };
    };

    config.withOverlays = cfg;
  };
}
