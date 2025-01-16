{
  config,
  lib,
  conflake,
  src,
  ...
}:

let
  inherit (builtins) mapAttrs;
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    mkOverride
    pipe
    types
    ;
  inherit (conflake.flake) lock2inputs;

  cfg = config.presets.inputs;

  flakeLockExists = (config.srcEntries."flake.lock" or "") == "regular";
in
{
  options.presets.inputs = {
    enable = mkEnableOption "auto inputs" // {
      default = config.presets.enable;
    };
    priority = mkOption {
      type = types.int;
      default = 950;
    };
  };

  config = mkIf (cfg.enable && config.inputs == null && flakeLockExists) {
    finalInputs = pipe (src + /flake.lock) [
      lock2inputs
      (mapAttrs (_: mkOverride cfg.priority))
    ];
  };
}
