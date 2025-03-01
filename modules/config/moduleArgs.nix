{ config, lib, ... }@args:

let
  inherit (lib) mkEnableOption mkIf;
  inherit (config) outputs;

  cfg = config.moduleArgs;
  inputs = config.finalInputs;
in
{
  options = {
    moduleArgs = {
      enable = mkEnableOption "moduleArgs" // {
        default = true;
      };
    };

  };

  config = mkIf cfg.enable {
    _module.args = {
      inherit inputs outputs;

      moduleArgs = args // config._module.args;
    };
  };
}
