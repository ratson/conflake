{ config, lib, ... }:

let
  inherit (lib) mkIf mkOption types;
  inherit (lib.types) lazyAttrsOf nullOr;

  cfg = config.inputs;
in
{
  options = {
    inputs = mkOption {
      type = nullOr (lazyAttrsOf types.raw);
      default = null;
    };

    finalInputs = mkOption {
      internal = true;
      type = lazyAttrsOf types.raw;
    };
  };

  config = mkIf (cfg != null) {
    finalInputs = cfg;
  };
}
