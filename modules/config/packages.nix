{ config, lib, conflake, genPkgs, ... }:

let
  inherit (lib) mapAttrs mkIf mkMerge mkOption optionalAttrs types;
in
{
  options = {
    package = mkOption {
      type = types.nullOr types.raw;
      default = null;
    };

    packages = mkOption {
      type = types.lazyAttrsOf types.raw;
      default = { };
    };

    pname = mkOption {
      type = types.nullOr types.str;
      default = null;
    };

    packagesOverlay = mkOption {
      type = types.uniq conflake.types.overlay;
      default = final: prev:
        let
          pkgs = mapAttrs (_: v: v prev) config.packages;
        in
        removeAttrs pkgs [ "default" ] // optionalAttrs
          (pkgs ? default && config.pname != null)
          { "${config.pname}" = pkgs.default; };
      internal = true;
      readOnly = true;
    };
  };

  config = mkMerge [
    (mkIf (config.nixDirEntries ? packages) {
      packages = config.nixDirEntries.packages;
    })

    (mkIf (config.package != null) {
      packages.default = config.package;
    })

    (mkIf (config.packages != { }) {
      outputs = {
        packages = genPkgs ({ callPackage, ... }:
          mapAttrs (_: f: callPackage f { })
            config.packages);

        overlays.default = config.packagesOverlay;
      };
    })
  ];
}
