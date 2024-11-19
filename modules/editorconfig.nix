{ config, lib, src, ... }:

let
  inherit (builtins) elem pathExists;
  inherit (lib) getExe mkEnableOption mkIf optionalString;

  platforms = lib.platforms.darwin ++ lib.platforms.linux;
in
{
  options.conflake.editorconfig =
    mkEnableOption "editorconfig check" // { default = true; };

  config.checks = mkIf (config.conflake.editorconfig && (pathExists (src + /.editorconfig))) {
    # By default, high false-positive flags are disabled.
    editorconfig = pkgs: optionalString (elem pkgs.stdenv.hostPlatform.system platforms) (
      "${getExe pkgs.editorconfig-checker}"
      + optionalString (!pathExists (src + /.ecrc))
        " -disable-indent-size -disable-max-line-length"
    );
  };
}
