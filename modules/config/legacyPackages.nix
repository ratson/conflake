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
    removeSuffix
    types
    ;
  inherit (lib.types) functionTo lazyAttrsOf;
  inherit (conflake.types) nullable;
in
{
  options.legacyPackages = mkOption {
    type = nullable (functionTo (lazyAttrsOf types.raw));
    default = null;
  };

  config = mkMerge [
    (mkIf (config.legacyPackages != null) {
      outputs.legacyPackages = genSystems config.legacyPackages;
    })

    {
      loaders = config.nixDir.mkLoader "legacyPackages" (
        { src, ... }:
        let
          entries = config.loadDir' (x: x // { name = removeSuffix ".nix" x.name; }) src;
          transform =
            pkgs:
            mapAttrs (
              _: v:
              if isAttrs v then
                if v ? default && isPath v.default then pkgs.callPackage v.default moduleArgs else transform pkgs v
              else
                pkgs.callPackage v moduleArgs
            );
          overlay = _: prev: {
            emacsPackagesFor =
              emacs:
              (prev.emacsPackagesFor emacs).overrideScope (
                final: _:
                mapAttrs (
                  _: flip final.callPackage { }
                ) config.loadedOutputs.legacyPackages.${prev.system}.emacsPackages
              );

            emacsPackages =
              prev.emacsPackages // config.loadedOutputs.legacyPackages.${prev.system}.emacsPackages;
          };
        in
        {
          inherit overlay;

          withOverlays = overlay;

          legacyPackages = flip transform entries;
        }
      );
    }
  ];
}
