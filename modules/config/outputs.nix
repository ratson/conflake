{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options = {
    outputs = mkOption {
      type = types.lazyAttrsOf types.raw;
      default = { };
    };
  };
}

