{
  lib,
  conflake,
  ...
}:

let
  inherit (lib) mkOption;
  inherit (conflake.types) optListOf overlay;
in
{
  options = {
    withOverlays = mkOption {
      type = optListOf overlay;
      default = [ ];
    };
  };
}
