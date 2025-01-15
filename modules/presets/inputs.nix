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
    mkOverride
    pipe
    ;
  inherit (conflake.flake) lock2inputs;

  flakeLockExists = (config.srcEntries."flake.lock" or "") == "regular";
in
{
  options.presets.inputs.enable = mkEnableOption "auto inputs" // {
    default = config.presets.enable;
  };

  config = mkIf (config.inputs == null && flakeLockExists) {
    finalInputs = pipe (src + /flake.lock) [
      lock2inputs
      (mapAttrs (_: mkOverride 950))
    ];
  };
}
