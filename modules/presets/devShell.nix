{ config, lib, ... }:

let
  inherit (lib)
    mkEnableOption
    mkIf
    ;

  cfg = config.presets.devShell;
in
{
  options.presets.devShell = {
    enable = mkEnableOption "default devShell" // {
      default = config.presets.enable;
    };
    formatters = mkEnableOption "formatter packages" // {
      default = cfg.enable;
    };
    package = mkEnableOption "default package" // {
      default = cfg.enable;
    };
  };

  config = mkIf (cfg.package && config.packages != null && config.packages ? default) {
    devShell.inputsFrom = { outputs' }: [ outputs'.packages.default ];
  };
}
