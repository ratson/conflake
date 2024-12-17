{ lib, ... }:

let
  inherit (lib) mkEnableOption;
in
{
  imports = [
    ./checks
    ./formatters.nix
    ./inputs.nix
    ./overlay
  ];

  options.presets.enable = mkEnableOption "presets" // {
    default = true;
  };
}
