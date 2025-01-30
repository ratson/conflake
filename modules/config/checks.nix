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
in
{
  options.checks = mkOption {
    type = nullable (optFunctionTo (conflake.types.checks src));
    default = null;
  };

  config = mkIf (config.checks != null) {
    outputs.checks = config.callSystemsWithAttrs config.checks;
  };
}
