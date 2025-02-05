{
  config,
  lib,
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
    pipe
    types
    ;
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
      checks = config.genSystems' (
        {
          editorconfig-checker,
          stdenv,
          pkgsCall,
        }:
        mkIf (elem stdenv.hostPlatform.system platforms) {
          editorconfig = pipe conflake.mkCheck [
            (conflake.callWith { name = "editorconfig"; })
            pkgsCall
            (
              f:
              f (
                concatStringsSep " " [
                  (getExe editorconfig-checker)
                  cfg.args
                ]
              )
            )
          ];
        }
      );
    };
  };
}
