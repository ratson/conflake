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
    optionalString
    ;
  inherit (conflake) mkCheck;

  platforms = lib.platforms.darwin ++ lib.platforms.linux;
in
{
  options.conflake.editorconfig = mkEnableOption "editorconfig check" // {
    default = true;
  };

  # By default, high false-positive flags are disabled.
  config = mkIf config.conflake.editorconfig {
    loaders.".editorconfig" = {
      match = conflake.matchers.file;
      load =
        { entries, ... }:
        {
          checks = genSystems (
            pkgs:
            mkIf (elem pkgs.stdenv.hostPlatform.system platforms) {
              editorconfig = mkCheck "editorconfig" pkgs src (
                "${getExe pkgs.editorconfig-checker}"
                + optionalString (
                  (entries.".ecrc" or "") != "regular"
                ) " -disable-indent-size -disable-max-line-length"
              );
            }
          );
        };
    };
  };
}
