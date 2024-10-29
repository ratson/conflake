{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options = {
    packages = mkOption {
      type = types.nullOr (types.attrsOf types.raw);
      default = null;
    };
  };
}

