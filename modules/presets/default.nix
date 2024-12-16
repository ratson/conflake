{ lib, ... }:

let
  inherit (lib) mkEnableOption;
in
{
  imports = [
    ./checks
    ./formatters.nix
    ./inputs.nix
  ];

  options.presets.enable = mkEnableOption "presets" // {
    default = true;
  };
}
