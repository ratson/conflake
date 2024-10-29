{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options = {
    perSystem = mkOption {
      type = types.nullOr (types.functionTo (types.lazyAttrsOf types.raw));
      default = null;
    };
  };
}
