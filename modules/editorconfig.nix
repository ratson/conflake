{ config, lib, src, ... }:

let
  inherit (builtins) pathExists;
  inherit (lib) getExe mkEnableOption mkIf optionalString;
in
{
  options.conflake.editorconfig =
    mkEnableOption "editorconfig check" // { default = true; };

  config.checks = mkIf
    (config.conflake.editorconfig && (pathExists (src + /.editorconfig)))
    {
      # By default, high false-positive flags are disabled.
      editorconfig = { editorconfig-checker, ... }:
        "${getExe editorconfig-checker}"
        + optionalString (!pathExists (src + /.ecrc))
          " -disable-indent-size -disable-max-line-length";
    };
}
