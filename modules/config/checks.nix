{
  config,
  lib,
  conflake,
  src,
  ...
}:

let
  inherit (builtins) mapAttrs;
  inherit (lib) mkIf mkOption;
  inherit (config) genSystems;
  inherit (conflake.types) nullable optFunctionTo;
in
{
  options.checks = mkOption {
    type = nullable (optFunctionTo (conflake.types.checks src));
    default = null;
  };

  config = mkIf (config.checks != null) {
    outputs.checks = genSystems (pkgs: mapAttrs (_: v: v pkgs) (config.checks pkgs));
  };
}
