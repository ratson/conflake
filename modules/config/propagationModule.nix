# This provides a module that can be added to module systems nested inside of
# conflake, for example NixOS or home-manager configurations.
{ lib, config, conflake, moduleArgs, inputs, outputs, ... }:

let
  inherit (builtins) mapAttrs;
  inherit (lib) mkOption optional optionalAttrs;
  inherit (conflake) selectAttr;
  inherit (conflake.types) module;
  flakeConfig = config;
in
{
  options.propagationModule = mkOption {
    type = module;
    internal = true;
  };

  config.propagationModule = { lib, pkgs, options, config, ... }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
    in
    {
      config = (optionalAttrs (options ? nixpkgs) {
        nixpkgs = (optionalAttrs (options ? nixpkgs.overlays) {
          # Forward overlays to NixOS/home-manager configurations
          overlays = lib.mkOrder 10
            (flakeConfig.withOverlays ++ [ flakeConfig.packageOverlay ]);
        })
        // (optionalAttrs (options ? nixpkgs.config) {
          # Forward nixpkgs.config to NixOS/home-manager configurations
          inherit (flakeConfig.nixpkgs) config;
        });
      })
      // (optionalAttrs (options ? home-manager.sharedModules) {
        # Propagate module to home-manager when using its nixos module
        home-manager.sharedModules =
          optional (! config.home-manager.useGlobalPkgs)
            [ flakeConfig.propagationModule ];
      })
      // {
        # Give access to conflake module args under `flake` arg.
        # Also include inputs'/outputs' which depend on `pkgs`.
        _module.args.flake = {
          inputs' = mapAttrs (_: selectAttr system) inputs;
          outputs' = selectAttr system outputs;
        } // moduleArgs;
      };
    };
}
