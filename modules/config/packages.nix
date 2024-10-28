{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options = {
    packages = mkOption {
      type = types.functionTo types.str;
      default = _: { };
    };
  };

  config = { };
}

