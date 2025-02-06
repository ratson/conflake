{ config, lib, ... }:

let
  inherit (builtins) mapAttrs;
  inherit (lib) flip mkEnableOption mkIf;

  cfg = config.presets.overlay.emacsPackages;

  overlay =
    _: prev:
    let
      inherit (prev.stdenv.hostPlatform) system;
      epkgs = config.outputs.legacyPackages.${system}.emacsPackages or { };
    in
    {
      emacsPackagesFor =
        emacs:
        (prev.emacsPackagesFor emacs).overrideScope (
          final: _: mapAttrs (_: flip final.callPackage { }) epkgs
        );

      emacsPackages = prev.emacsPackages // epkgs;
    };
in
{
  options.presets.overlay.emacsPackages = mkEnableOption "emacsPackages overlay" // {
    default = config.presets.overlay.enable;
  };

  config = mkIf (cfg && config.legacyPackages != null) {
    inherit overlay;

    nixpkgs.overlays = [ overlay ];
  };
}
