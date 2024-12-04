{
  config,
  lib,
  genSystems,
  src,
  conflake,
  ...
}:

let
  inherit (builtins) elem;
  inherit (lib)
    getExe
    mkEnableOption
    mkIf
    mkOption
    optionalString
    types
    ;
  inherit (conflake) mkCheck;

  cfg = config.editorconfig;

  platforms = lib.platforms.darwin ++ lib.platforms.linux;

  mkArgs =
    entries:
    if (cfg.checkArgs != null) then
      cfg.checkArgs
    else
      # By default, high false-positive flags are disabled.
      optionalString (
        (entries.".ecrc" or "") != "regular"
      ) " -disable-indent-size -disable-max-line-length";
in
{
  options.editorconfig = {
    check = mkEnableOption "editorconfig check" // {
      default = true;
    };

    checkArgs = mkOption {
      type = types.nullOr types.str;
      default = null;
    };
  };

  config = {
    loaders.".editorconfig" = {
      enable = cfg.check;
      match = conflake.matchers.file;
      load =
        { entries, ... }:
        {
          outputs.checks = genSystems (
            pkgs:
            mkIf (elem pkgs.stdenv.hostPlatform.system platforms) {
              editorconfig = mkCheck "editorconfig" pkgs src (
                "${getExe pkgs.editorconfig-checker}" + (mkArgs entries)
              );
            }
          );
        };
    };
  };
}
