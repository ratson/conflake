{
  config,
  lib,
  conflake,
  ...
}:

let
  inherit (builtins) mapAttrs;
  inherit (lib)
    filterAttrs
    mkEnableOption
    mkIf
    pipe
    ;
  inherit (conflake) prefixAttrs;
  inherit (conflake.loaders) mkPackageCheck;

  cfg = config.presets.checks.home;
in
{
  options.presets.checks.home = {
    enable = mkEnableOption "home configuration check" // {
      default = config.presets.checks.enable;
    };
  };

  config = mkIf (cfg.enable && config.homeConfigurations != { }) {
    outputs.checks = config.genSystems (
      { pkgs, system, ... }:
      pipe config.outputs.homeConfigurations [
        (filterAttrs (_: v: v.pkgs.system == system))
        (prefixAttrs "home-")
        (mapAttrs (_: v: v.activationPackage))
        (mapAttrs (mkPackageCheck pkgs))
      ]
    );
  };
}
