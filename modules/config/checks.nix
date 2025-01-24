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
  inherit (lib.types) lazyAttrsOf;
  inherit (config) genSystems;
  inherit (conflake.types) nullable optFunctionTo;
in
{
  options.checks = mkOption {
    type = nullable (optFunctionTo (lazyAttrsOf (conflake.types.mkCheck src)));
    default = null;
  };

  config = mkIf (config.checks != null) {
    outputs.checks = genSystems (pkgs: mapAttrs (_: v: v pkgs) (config.checks pkgs));
  };
}
