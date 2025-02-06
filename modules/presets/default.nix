{ lib, ... }:

let
  inherit (lib) mkEnableOption;
in
{
  imports = [
    ./checks/default.nix
    ./devShell.nix
    ./formatters.nix
    ./inputs.nix
    ./overlay/default.nix
  ];

  options.presets.enable = mkEnableOption "presets" // {
    default = true;
  };
}
