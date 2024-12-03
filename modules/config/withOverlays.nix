{
  config,
  lib,
  conflake,
  ...
}:

let
  inherit (lib) mkIf mkOption;
  inherit (conflake.types) optListOf overlay;
in
{
  options = {
    withOverlays = mkOption {
      type = optListOf overlay;
      default = [ ];
    };
  };

  config = mkIf (config.loadedOutputs.withOverlays != [ ]) {
    inherit (config.loadedOutputs) withOverlays;
  };
}
