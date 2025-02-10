{
  config,
  lib,
  conflake,
  ...
}:

let
  inherit (lib)
    escapeShellArgs
    mkEnableOption
    mkIf
    mkOption
    optionalString
    types
    ;
  inherit (lib.types) listOf;
  inherit (conflake.loaders) mkCheck;

  cfg = config.presets.checks.deadnix;
in
{
  options.presets.checks.deadnix = {
    enable = mkEnableOption "deadnix check" // {
      default = false;
    };
    exclude = mkOption {
      type = listOf types.str;
      default = [ ];
    };
    files = mkOption {
      type = listOf types.str;
      default = [ ];
    };
  };

  config = mkIf cfg.enable {
    checks.deadnix = mkCheck (pkgs: [ pkgs.deadnix ]) ''
      deadnix ${
        optionalString (cfg.exclude != null) "--exclude ${escapeShellArgs cfg.exclude}"
      } --fail ${escapeShellArgs cfg.files}
    '';
  };
}
