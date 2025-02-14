{
  config,
  lib,
  inputs,
  ...
}:

let
  inherit (lib)
    flip
    mkEnableOption
    mkIf
    pipe
    ;

  cfg = config.presets.overlay.emacsPackages;

  overlay =
    _: prev:
    let
      inherit (prev.stdenv.hostPlatform) system;
      epkgs = inputs.self.legacyPackages.${system}.emacsPackages or { };
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
  options.presets.overlay.emacsPackages = mkEnableOption "emacsPackages overlay" // {
    default = config.presets.overlay.enable;
  };

  config = mkIf (cfg && config.legacyPackages != null) {
    inherit overlay;

    nixpkgs.overlays = [ overlay ];
  };
}
