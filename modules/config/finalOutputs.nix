{ config, lib, ... }@args:

let
  inherit (builtins) mapAttrs;

  inherit (lib) attrNames functionArgs genAttrs getAttrs
    mkDefault mkIf mkMerge mkOption types;

  inherit (config) inputs;

  packages = mapAttrs
    (system: pkgs:
      mapAttrs (_: v: pkgs.callPackage v { }) config.nixDirEntries.packages or { })
    config.pkgsBySystem;

  nixosConfigurations = mapAttrs
    (_: v: inputs.nixpkgs.lib.nixosSystem (
      import v args
    ))
    config.nixDirEntries.nixos or { };

  nixosModules = mapAttrs
    (_: nixosModule:
      (_: {
        imports = [
          {
            _module.args = mapAttrs (_: v: mkDefault v) {
              inherit inputs;
            };
          }
          nixosModule
        ];
      })
    )
    config.nixDirEntries.nixosModules or { };
in
{
  options = {
    finalOutputs = mkOption {
      type = types.submodule {
        freeformType = types.lazyAttrsOf types.raw;
        options = {
          nixosConfigurations = mkOption {
            type = types.attrsOf types.raw;
          };
          packages = mkOption {
            type = types.attrsOf (types.attrsOf types.raw);
          };
        };
      };
      readOnly = true;
      visible = false;
    };

    pkgsBySystem = mkOption {
      type = types.lazyAttrsOf types.raw;
      default = genAttrs config.systems (system: import inputs.nixpkgs {
        inherit system;
      });
      readOnly = true;
      visible = false;
    };
  };

  config = {
    finalOutputs = mkMerge [
      { inherit nixosConfigurations nixosModules packages; }
      {
        packages = mapAttrs
          (system: pkgs:
            mapAttrs (_: f: f (getAttrs (attrNames (functionArgs f)) { inherit lib pkgs system; })) config.packages)
          config.pkgsBySystem;
      }
      (mkIf (config.outputs != null) config.outputs)
    ];
  };
}