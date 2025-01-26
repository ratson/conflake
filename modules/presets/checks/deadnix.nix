{ config, lib, ... }:

let
  inherit (builtins) concatStringsSep elem;
  inherit (lib)
    escapeShellArgs
    getExe
    mkEnableOption
    mkIf
    mkOption
    optionalString
    types
    ;
  inherit (lib.types) listOf;

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
    checks.deadnix =
      pkgs:
      optionalString (!elem pkgs.stdenv.hostPlatform.system [ "x86_64-freebsd" ]) (
        concatStringsSep " " [
          (getExe pkgs.deadnix)
          (optionalString (cfg.exclude != null) "--exclude ${escapeShellArgs cfg.exclude}")
          "--fail"
          (escapeShellArgs cfg.files)
        ]
      );
  };
}
