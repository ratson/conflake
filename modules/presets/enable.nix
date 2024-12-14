{ lib, ... }:

let
  inherit (lib) mkEnableOption;
in
{
  options.presets.enable = mkEnableOption "presets" // {
    default = true;
  };
}
