{
  lib,
  conflake,
  ...
}:

let
  inherit (lib) mkOption;
  inherit (lib.types) lazyAttrsOf raw;
  inherit (conflake.types) optListOf overlay;
in
{
  options.nixpkgs = {
    config = mkOption {
      type = lazyAttrsOf raw;
      default = { };
    };
    overlays = mkOption {
      type = optListOf overlay;
      default = [ ];
    };
  };
}
