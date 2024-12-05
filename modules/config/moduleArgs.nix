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
  inherit (config) inputs;
  inherit (conflake) selectAttr;

  cfg = config.moduleArgs;

  pkgsFor = genAttrs config.systems (
    system:
    import inputs.nixpkgs {
      inherit system;
      inherit (config.nixpkgs) config;

      overlays = config.withOverlays ++ [ config.packageOverlay ];
    }
  );

  genSystems = f: genAttrs config.systems (system: f pkgsFor.${system});

  mkSpecialArgs = system: {
    inherit inputs;

    inputs' = mapAttrs (_: selectAttr system) inputs;
  };
in
{
  options = {
    moduleArgs = mkOption {
      type = types.submodule {
        options = {
          enable = mkEnableOption "moduleArgs" // {
            default = true;
          };
          extra = mkOption {
            type = types.lazyAttrsOf types.raw;
            default = { };
          };
        };
      };
      default = { };
    };
  };

  config = {
    _module.args = {
      inherit
        inputs
        mkSpecialArgs
        pkgsFor
        genSystems
        ;
      inherit (config) outputs;

      moduleArgs = args // config._module.args // cfg.extra;
    };
  };
}
