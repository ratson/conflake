{
  config,
  lib,
  conflake,
  ...
}:

let
  inherit (lib)
    escapeShellArg
    mkEnableOption
    mkIf
    mkOption
    optionalString
    types
    ;
  inherit (conflake.loaders) mkCheck;

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
    checks.statix = mkCheck (pkgs: [ pkgs.statix ]) ''
      statix check ${
        optionalString (cfg.ignore != null) "--ignore=${escapeShellArg cfg.ignore}"
      } ${optionalString cfg.unrestricted "--unrestricted"}
    '';
  };
}
