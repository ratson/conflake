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
    mkIf
    mkMerge
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

  mkSystemArgs = system: {
    inputs' = mapAttrs (_: selectAttr system) inputs;
    outputs' = selectAttr system outputs;
  };

  mkSystemArgs' = pkgs: mkSystemArgs pkgs.stdenv.hostPlatform.system;
in
{
  options = {
    moduleArgs = {
      enable = mkEnableOption "moduleArgs" // {
        default = true;
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

  config = mkMerge [
    (mkIf cfg.enable { })
    {
      _module.args = {
        inherit inputs outputs;

        moduleArgs = args // config._module.args;
      };
    }
  ];
}
