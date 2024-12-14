{ config, lib, ... }:

let
  inherit (builtins) concatStringsSep;
  inherit (lib)
    escapeShellArg
    getExe
    mkEnableOption
    mkIf
    mkOption
    optionalString
    types
    ;

  cfg = config.presets.checks.statix;
in
{
  options.presets.checks.statix = {
    enable = mkEnableOption "statix check" // {
      default = config.presets.checks.enable;
    };
    ignore = mkOption {
      type = types.nullOr types.str;
      default = null;
    };
    unrestricted = mkEnableOption "unrestricted";
  };

  config = mkIf cfg.enable {
    checks.statix =
      pkgs:
      concatStringsSep " " [
        (getExe pkgs.statix)
        "check"
        (optionalString (cfg.ignore != null) "--ignore=${escapeShellArg cfg.ignore}")
        (optionalString cfg.unrestricted "--unrestricted")
      ];
  };
}
