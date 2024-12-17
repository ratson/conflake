{ config, lib, ... }:

let
  inherit (lib) mkEnableOption;
in
{
  imports = [
    ./emacsPackages.nix
    ./packages.nix
  ];

  options.presets.overlay.enable = mkEnableOption "default overlay" // {
    default = config.presets.enable;
  };
}
