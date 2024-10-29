{ config, lib, conflake, ... }:

let
  inherit (builtins) head mapAttrs match;

  inherit (lib) attrValues foldAttrs genAttrs
    mergeAttrs mkDefault mkIf mkMerge mkOption types;

  inherit (config) inputs;

  genPkgs = f: mapAttrs
    (system: pkgs: f {
      inherit pkgs system;

      callPackage = f: args: pkgs.callPackage f (
        config.moduleArgs // { inherit pkgs system; } // args
      );
    })
    config.pkgsBySystem;
in
{
  options = {
    finalOutputs = mkOption {
      type = conflake.types.outputs;
      readOnly = true;
      visible = false;
    };

    pkgsBySystem = mkOption {
      type = types.lazyAttrsOf types.raw;
      default = genAttrs config.systems (system:
        inputs.nixpkgs.legacyPackages.${system});
      readOnly = true;
      visible = false;
    };
  };

  config = {
    finalOutputs = mkMerge [
      (mkIf (config.nixDirEntries ? home) {
        homeConfigurations = mapAttrs
          (name: v: inputs.home-manager.lib.homeManagerConfiguration (
            let
              cfg = import v;
              username = head (match "([^@]*)(@.*)?" name);
            in
            (removeAttrs cfg [ "system" ] // {
              modules = [
                config.argsModule
                { home.username = mkDefault username; }
              ] ++ cfg.modules or [ ];
              pkgs = inputs.nixpkgs.legacyPackages.${cfg.system};
            })
          ))
          config.nixDirEntries.home;
      })

      (mkIf (config.nixDirEntries ? homeModules) {
        homeModules = mapAttrs
          (_: homeModule: (_: {
            imports = [
              config.argsModule
              homeModule
            ];
          }))
          config.nixDirEntries.homeModules;
      })

      (mkIf (config.nixDirEntries ? lib) {
        lib = mapAttrs (_: v: import v)
          config.nixDirEntries.lib;
      })

      (mkIf (config.nixDirEntries ? nixos) {
        nixosConfigurations = mapAttrs
          (_: v: inputs.nixpkgs.lib.nixosSystem (
            import v
          ))
          config.nixDirEntries.nixos;
      })

      (mkIf (config.nixDirEntries ? nixosModules) {
        nixosModules = mapAttrs
          (_: nixosModule: (_: {
            imports = [
              config.argsModule
              nixosModule
            ];
          }))
          config.nixDirEntries.nixosModules;
      })

      (mkIf (config.nixDirEntries ? packages) {
        packages = genPkgs ({ callPackage, ... }:
          mapAttrs (_: v: callPackage v { })
            config.nixDirEntries.packages
        );
      })

      (mkIf (config.packages != null) {
        packages = genPkgs ({ callPackage, ... }:
          mapAttrs (_: f: callPackage f { })
            config.packages);
      })

      (mkIf (config.perSystem != null) (
        foldAttrs mergeAttrs { } (attrValues (
          genPkgs ({ system, callPackage, ... }:
            mapAttrs (_: v: { ${system} = v; })
              (callPackage config.perSystem { })
          )
        ))
      ))

      (mkIf (config.outputs != null) config.outputs)
    ];
  };
}
