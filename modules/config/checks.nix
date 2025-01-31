{
  config,
  lib,
  conflake,
  src,
  ...
}:

let
  inherit (lib) mkIf mkOption;
  inherit (conflake.types) nullable optFunctionTo;

  cfg = config.checks;
in
{
  options.checks = mkOption {
    type = nullable (optFunctionTo (conflake.types.checks src));
    default = null;
  };

  config = mkIf (cfg != null) {
    outputs.checks = config.callSystemsWithAttrs cfg;
  };
}
