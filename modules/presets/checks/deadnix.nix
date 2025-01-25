{ config, lib, ... }:

let
  inherit (builtins) concatStringsSep elem;
  inherit (lib)
    escapeShellArg
    escapeShellArgs
    getExe
    mkEnableOption
    mkIf
    mkOption
    optionalString
    types
    ;

  cfg = config.presets.checks.deadnix;
in
{
  options.presets.checks.deadnix = {
    enable = mkEnableOption "deadnix check" // {
      default = false;
    };
    exclude = mkOption {
      type = types.nullOr types.str;
      default = null;
    };
    files = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };
  };

  config = mkIf cfg.enable {
    checks.deadnix =
      pkgs:
      optionalString (!elem pkgs.stdenv.hostPlatform.system [ "x86_64-freebsd" ]) (
        concatStringsSep " " [
          (getExe pkgs.deadnix)
          (optionalString (cfg.exclude != null) "--exclude=${escapeShellArg cfg.exclude}")
          "--fail"
          (escapeShellArgs cfg.files)
        ]
      );
  };
}
