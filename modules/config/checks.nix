{
  config,
  lib,
  conflake,
  genSystems,
  src,
  ...
}:

let
  inherit (builtins) mapAttrs;
  inherit (lib)
    mkIf
    mkMerge
    mkOption
    types
    ;
  inherit (lib.types) lazyAttrsOf;
  inherit (conflake.types) nullable optFunctionTo;

  cfg = config.checks;
in
{
  options.checks = mkOption {
    type = types.unspecified;
    default = null;
  };

  config.final =
    { config, ... }:
    {
      options.checks = mkOption {
        type = nullable (optFunctionTo (lazyAttrsOf (conflake.types.mkCheck src)));
        default = null;
      };

      config = mkMerge [
        { checks = cfg; }

        (mkIf (config.checks != null) {
          outputs.checks = genSystems (pkgs: mapAttrs (_: v: v pkgs) (config.checks pkgs));
        })
      ];
    };
}
