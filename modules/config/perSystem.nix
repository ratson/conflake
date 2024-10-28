{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options = {
    perSystem = mkOption {
      type = types.functionTo types.str;
      default = _: { };
    };
  };
}

