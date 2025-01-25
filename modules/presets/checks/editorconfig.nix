{
  config,
  lib,
  conflake,
  src,
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
  inherit (config) genSystems;
  inherit (config.src) has;

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
      default = optionalString (!(has ".ecrc")) "-disable-indent-size -disable-max-line-length";
    };
  };

  config = mkIf (cfg.enable && has ".editorconfig") {
    loaders.outputs = _: {
      checks = genSystems (
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
}
