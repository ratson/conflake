{
  config,
  lib,
  conflake,
  genSystems,
  moduleArgs,
  ...
}:

let
  inherit (builtins) isAttrs isPath mapAttrs;
  inherit (lib)
    flip
    mkIf
    mkMerge
    mkOption
    nameValuePair
    removeSuffix
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
        if epkgs == { } then
          prev.emacsPackages emacs
        else
          (prev.emacsPackagesFor emacs).overrideScope (
            final: _: mapAttrs (_: flip final.callPackage { }) epkgs
          );

      emacsPackages = prev.emacsPackages // epkgs;
    };
in
{
  options.legacyPackages = mkOption {
    type = nullable (functionTo (lazyAttrsOf types.raw));
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
        let
          entries = config.loadDir' (x: nameValuePair (removeSuffix ".nix" x.name) x.value) src;
          transform =
            pkgs:
            mapAttrs (
              _: v:
              if isAttrs v then
                if v ? default && isPath v.default then pkgs.callPackage v.default moduleArgs else transform pkgs v
              else
                pkgs.callPackage v moduleArgs
            );
        in
        {
          legacyPackages = flip transform entries;
        }
      );
    }
  ];
}
