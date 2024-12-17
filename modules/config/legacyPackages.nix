{
  config,
  lib,
  conflake,
  genSystems,
  moduleArgs,
  ...
}:

let
  inherit (builtins) mapAttrs;
  inherit (lib)
    flip
    mkIf
    mkMerge
    mkOption
    types
    ;
  inherit (lib.types) functionTo lazyAttrsOf;
  inherit (conflake.types) nullable;

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
  options.legacyPackages = mkOption {
    type = nullable (functionTo (lazyAttrsOf types.unspecified));
    default = null;
  };

  config = mkMerge [
    (mkIf (config.legacyPackages != null) {
      inherit overlay;

      withOverlays = overlay;

      outputs.legacyPackages = genSystems config.legacyPackages;
    })

    {
      loaders = config.nixDir.mkLoader "legacyPackages" (
        { src, ... }:
        {
          legacyPackages =
            pkgs:
            config.loadDirWithDefault {
              root = src;
              load = flip pkgs.callPackage moduleArgs;
            };
        }
      );
    }
  ];
}
