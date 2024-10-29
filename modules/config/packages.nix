{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options = {
    packages = mkOption {
      type = types.attrsOf types.raw;
      default = _: { };
    };
  };
}

