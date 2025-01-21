{
  config,
  lib,
  conflake,
  genSystems,
  src,
  ...
}:

let
  inherit (builtins) concatStringsSep elem isPath;
  inherit (lib)
    getExe
    mkEnableOption
    mkIf
    mkOption
    optionalString
    types
    ;

  cfg = config.presets.checks.editorconfig;

  platforms = lib.platforms.darwin ++ lib.platforms.linux;
in
{
  options.presets.checks.editorconfig = {
    enable = mkEnableOption "editorconfig check" // {
      default = config.presets.checks.enable;
    };
    args = mkOption {
      type = types.str;
      # By default, high false-positive flags are disabled.
      default = optionalString (
        !isPath (config.srcTree.".ecrc" or null)
      ) "-disable-indent-size -disable-max-line-length";
    };
  };

  config = mkIf cfg.enable {
    loaders.".editorconfig" = {
      match = conflake.matchers.file;
      load = _: {
        outputs.checks = genSystems (
          pkgs:
          mkIf (elem pkgs.stdenv.hostPlatform.system platforms) {
            editorconfig = conflake.mkCheck "editorconfig" pkgs src (
              concatStringsSep " " [
                (getExe pkgs.editorconfig-checker)
                cfg.args
              ]
            );
          }
        );
      };
    };
  };
}
