{
  config,
  lib,
  conflake,
  ...
}:

let
  inherit (lib) mkIf mkOption;
  inherit (conflake.types) nullable;

  cfg = config.checks;
in
{
  options.checks = mkOption {
    type = nullable conflake.types.checks;
    default = null;
  };

  config = mkIf (cfg != null) {
    outputs.checks = config.callSystemsWithAttrs cfg;
  };
}
