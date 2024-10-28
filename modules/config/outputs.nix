{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options = {
    outputs = mkOption {
      type = types.nullOr (types.lazyAttrsOf types.raw);
      default = null;
    };
  };
}

