{ config, lib, ... }:

let
  inherit (lib) mkEnableOption;
in
{
  imports = [
    ./deadnix.nix
    ./editorconfig.nix
    ./formatting.nix
    ./packages.nix
    ./tests.nix
    ./statix.nix
  ];

  options.presets.checks.enable = mkEnableOption "default checks" // {
    default = config.presets.enable;
  };
}
