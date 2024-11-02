{ config, lib, conflake, moduleArgs, inputs, outputs, ... }:

let
  inherit (builtins) mapAttrs;
  inherit (lib) mkIf mkMerge mkOption mkOrder optional optionalAttrs;
  inherit (conflake) selectAttr;
  inherit (conflake.types) module;

  rootConfig = config;
in
{
  options.propagationModule = mkOption {
    type = module;
    internal = true;
    description = ''
      A module that can be added to module systems nested inside of Conflake,
      for example NixOS or home-manager configurations.
    '';
  };

  config.propagationModule = { config, options, lib, pkgs, ... }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
    in
    {
      _file = ./propagationModule.nix;

      config = mkMerge [
        {
          # Give access to conflake module args under `flake` arg.
          # Also include inputs'/outputs' which depend on `pkgs`.
          _module.args.flake = {
            inputs' = mapAttrs (_: selectAttr system) inputs;
            outputs' = selectAttr system outputs;
          } // moduleArgs;
        }
        (mkIf (options ? nixpkgs) {
          nixpkgs = mkMerge [
            (mkIf (options ? nixpkgs.overlays) {
              # Forward overlays to NixOS/home-manager configurations
              overlays = mkOrder 10
                (rootConfig.withOverlays ++ [ rootConfig.packageOverlay ]);
            })
            (mkIf (options ? nixpkgs.config) {
              # Forward nixpkgs.config to NixOS/home-manager configurations
              inherit (rootConfig.nixpkgs) config;
            })
          ];
        })
        (optionalAttrs (options ? home-manager.sharedModules) {
          # Propagate module to home-manager when using its nixos module
          home-manager.sharedModules =
            optional (! config.home-manager.useGlobalPkgs)
              [ rootConfig.propagationModule ];
        })
      ];
    };
}
