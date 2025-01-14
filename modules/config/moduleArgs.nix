{
  config,
  lib,
  conflake,
  ...
}@args:

let
  inherit (builtins) mapAttrs;
  inherit (lib)
    genAttrs
    mkEnableOption
    mkOption
    types
    ;
  inherit (config) systems;
  inherit (conflake) selectAttr;

  cfg = config.moduleArgs;
  inputs = config.finalInputs;
  rootConfig = config;
in
{
  options.moduleArgs = {
    enable = mkEnableOption "moduleArgs" // {
      default = true;
    };
    extra = mkOption {
      type = types.lazyAttrsOf types.raw;
      default = { };
    };
  };

  config = {
    _module.args = {
      inherit inputs;
      inherit (config.final)
        genSystems
        mkSystemArgs
        mkSystemArgs'
        outputs
        pkgsFor
        ;

      moduleArgs = args // config._module.args // cfg.extra;
    };

    final =
      { config, ... }:
      {
        options = {
          pkgsFor = mkOption {
            internal = true;
            readOnly = true;
            type = types.unspecified;
            default = genAttrs systems (
              system:
              import inputs.nixpkgs {
                inherit system;
                inherit (rootConfig.nixpkgs) config;

                overlays = config.withOverlays ++ [ config.packageOverlay ];
              }
            );
          };
          genSystems = mkOption {
            internal = true;
            readOnly = true;
            type = types.unspecified;
            default = f: genAttrs systems (system: f config.pkgsFor.${system});
          };
          mkSystemArgs' = mkOption {
            internal = true;
            readOnly = true;
            type = types.unspecified;
            default =
              pkgs:
              let
                inherit (pkgs.stdenv.hostPlatform) system;
              in
              {
                inputs' = mapAttrs (_: selectAttr system) inputs;
                outputs' = selectAttr system config.outputs;
              };
          };
          mkSystemArgs = mkOption {
            internal = true;
            readOnly = true;
            type = types.unspecified;
            default = system: config.mkSystemArgs' config.pkgsFor.${system};
          };
        };

        config._module = {
          inherit (rootConfig._module) args;
        };
      };
  };
}
