{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options = {
    src = mkOption {
      type = types.path;
    };
  };
}

