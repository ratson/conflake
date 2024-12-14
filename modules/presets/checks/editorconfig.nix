{
  config,
  lib,
  genSystems,
  src,
  conflake,
  ...
}:

let
  inherit (builtins) concatStringsSep elem;
  inherit (lib)
    getExe
    mkEnableOption
    mkIf
    mkOption
    optionalString
    types
    ;
  inherit (conflake) mkCheck;

  cfg = config.presets.checks.editorconfig;

  platforms = lib.platforms.darwin ++ lib.platforms.linux;

  mkArgs =
    entries:
    if (cfg.args != null) then
      cfg.args
    else
      # By default, high false-positive flags are disabled.
      optionalString (
        (entries.".ecrc" or "") != "regular"
      ) "-disable-indent-size -disable-max-line-length";
in
{
  options.presets.checks.editorconfig = {
    enable = mkEnableOption "editorconfig check" // {
      default = config.presets.checks.enable;
    };
    args = mkOption {
      type = types.nullOr types.str;
      default = null;
    };
  };

  config = mkIf cfg.enable {
    loaders.".editorconfig" = {
      match = conflake.matchers.file;
      load =
        { entries, ... }:
        {
          outputs.checks = genSystems (
            pkgs:
            mkIf (elem pkgs.stdenv.hostPlatform.system platforms) {
              editorconfig = mkCheck "editorconfig" pkgs src (
                concatStringsSep " " [
                  (getExe pkgs.editorconfig-checker)
                  (mkArgs entries)
                ]
              );
            }
          );
        };
    };
  };
}
