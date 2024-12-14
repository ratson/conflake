{ lib, ... }:

let
  inherit (lib) mkEnableOption;
in
{
  imports = [
    ./checks
    ./formatters.nix
  ];

  options.presets.enable = mkEnableOption "presets" // {
    default = true;
  };
}
