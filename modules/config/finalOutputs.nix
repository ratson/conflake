{ config, lib, ... }@args:

let
  inherit (builtins) mapAttrs;

  inherit (lib) attrValues callPackageWith foldAttrs genAttrs
    mergeAttrs mkDefault mkIf mkMerge mkOption types;

  inherit (config) inputs;

  moduleArgs = mapAttrs (_: v: mkDefault v) {
    inherit inputs;
  };

  callWith = callPackageWith (moduleArgs // { inherit lib; });

  packages = mapAttrs
    (system: pkgs: mapAttrs
      (_: v: pkgs.callPackage v moduleArgs)
      config.nixDirEntries.packages or { })
    config.pkgsBySystem;

  homeModules = mapAttrs
    (_: homeModule: (_: {
      imports = [
        { _module.args = moduleArgs; }
        homeModule
      ];
    }))
    config.nixDirEntries.homeModules or { };

  nixosConfigurations = mapAttrs
    (_: v: inputs.nixpkgs.lib.nixosSystem (
      import v args
    ))
    config.nixDirEntries.nixos or { };

  nixosModules = mapAttrs
    (_: nixosModule: (_: {
      imports = [
        { _module.args = moduleArgs; }
        nixosModule
      ];
    }))
    config.nixDirEntries.nixosModules or { };

  perSystemOutputs = foldAttrs mergeAttrs { } (attrValues (mapAttrs
    (system: pkgs: mapAttrs
      (_: v: { ${system} = v; })
      (callWith config.perSystem {
        inherit pkgs system;
      }))
    config.pkgsBySystem));
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
      { inherit homeModules nixosConfigurations nixosModules packages; }

      (mkIf (config.packages != null) {
        packages = mapAttrs
          (system: pkgs:
            mapAttrs (_: f: callWith f { inherit pkgs system; })
              config.packages)
          config.pkgsBySystem;
      })

      (mkIf (config.perSystem != null) perSystemOutputs)
      (mkIf (config.outputs != null) config.outputs)
    ];
  };
}
