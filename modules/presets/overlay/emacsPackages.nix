{ config, lib, ... }:

let
  inherit (lib)
    flip
    mkEnableOption
    mkIf
    mkOption
    pipe
    removeAttrs
    types
    ;

  cfg = config.presets.overlay.emacsPackages;

  mkOverlay =
    blacklist: _: prev:
    let
      inherit (prev.stdenv.hostPlatform) system;
      epkgs = pipe system [
        (x: config.outputs.legacyPackages.${x}.emacsPackages or { })
        (flip removeAttrs blacklist)
      ];
    in
    {
      emacsPackagesFor = flip pipe [
        prev.emacsPackagesFor
        (x: x.overrideScope (_: _: epkgs))
      ];

      emacsPackages = prev.emacsPackages // epkgs;
    };
in
{
  options.presets.overlay.emacsPackages = {
    enable = mkEnableOption "emacsPackages overlay" // {
      default = config.presets.overlay.enable;
    };
    blacklist = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };
  };

  config = mkIf (cfg.enable && config.legacyPackages != null) {
    nixpkgs.overlays = [ (mkOverlay [ ]) ];

    overlay = mkOverlay cfg.blacklist;
  };
}
