{
  lib,
  conflake,
  ...
}:

let
  inherit (lib) mkOption;
in
{
  options = {
    withOverlays = mkOption {
      type = conflake.types.overlays;
      default = [ ];
    };
  };
}
