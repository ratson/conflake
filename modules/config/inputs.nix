{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options = {
    inputs = mkOption {
      type = types.lazyAttrsOf types.raw;
    };
  };
}

