{ lib, conflake, ... }:

let
  inherit (lib) mkOption types;
in
{
  options = {
    outputs = mkOption {
      type = types.nullOr conflake.types.outputs;
      default = null;
    };
  };
}

