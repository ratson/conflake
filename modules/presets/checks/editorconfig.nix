{
  config,
  lib,
  conflake,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    optionalString
    types
    ;
  inherit (config.src) has;
  inherit (conflake.loaders) mkCheck;

  cfg = config.presets.checks.editorconfig;
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
    checks.editorconfig = mkCheck (pkgs: [ pkgs.editorconfig-checker ]) ''
      editorconfig-checker ${cfg.args}
    '';
  };
}
