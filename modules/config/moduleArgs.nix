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
  inherit (config) outputs systems;
  inherit (conflake) selectAttr;

  cfg = config.moduleArgs;
  inputs = config.finalInputs;

  pkgsFor = genAttrs systems (
    system:
    import inputs.nixpkgs {
      inherit system;
      inherit (config.nixpkgs) config;

      overlays = config.withOverlays ++ [ config.packageOverlay ];
    }
  );

  genSystems = f: genAttrs systems (system: f pkgsFor.${system});

  mkSystemArgs' =
    pkgs:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
    in
    {
      inputs' = mapAttrs (_: selectAttr system) inputs;
      outputs' = selectAttr system outputs;
    };

  mkSystemArgs = system: mkSystemArgs' pkgsFor.${system};
in
{
  options = {
    moduleArgs = {
      enable = mkEnableOption "moduleArgs" // {
        default = true;
      };
      extra = mkOption {
        type = types.lazyAttrsOf types.raw;
        default = { };
      };
    };

    pkgsFor = mkOption {
      internal = true;
      readOnly = true;
      type = types.unspecified;
      default = pkgsFor;
    };
    genSystems = mkOption {
      internal = true;
      readOnly = true;
      type = types.unspecified;
      default = genSystems;
    };
    mkSystemArgs' = mkOption {
      internal = true;
      readOnly = true;
      type = types.unspecified;
      default = mkSystemArgs';
    };
    mkSystemArgs = mkOption {
      internal = true;
      readOnly = true;
      type = types.unspecified;
      default = mkSystemArgs;
    };
  };

  config = {
    _module.args = {
      inherit
        inputs
        outputs
        genSystems
        mkSystemArgs
        mkSystemArgs'
        pkgsFor
        ;

      moduleArgs = args // config._module.args // cfg.extra;
    };
  };
}
