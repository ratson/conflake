{
  config,
  lib,
  conflake,
  ...
}:

let
  inherit (lib) mkIf mkOption;
  inherit (lib.types) nullOr;

  cfg = config.inputs;
in
{
  options = {
    inputs = mkOption {
      type = nullOr conflake.types.inputs;
      default = null;
    };

    finalInputs = mkOption {
      internal = true;
      type = conflake.types.inputs;
    };
  };

  config = mkIf (cfg != null) {
    finalInputs = cfg;
  };
}
