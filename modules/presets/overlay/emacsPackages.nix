{ config, lib, ... }:

let
  inherit (builtins) mapAttrs;
  inherit (lib) flip mkEnableOption mkIf;

  cfg = config.presets.overlay.emacsPackages;
in
{
  options.presets.overlay.emacsPackages = mkEnableOption "emacsPackages overlay" // {
    default = config.presets.overlay.enable;
  };

  config.final =
    { config, ... }:
    let
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
      config = mkIf (cfg && config.legacyPackages != null) {
        inherit overlay;

        withOverlays = overlay;
      };
    };
}
