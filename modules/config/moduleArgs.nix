{
  config,
  lib,
  inputs,
  ...
}@args:

let
  inherit (lib)
    genAttrs
    mkEnableOption
    mkOption
    types
    ;

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
            type = types.submodule {
              freeformType = types.raw;
            };
            default = { };
          };
        };
      };
      default = { };
    };
  };

  config = {
    _module.args = {
      inherit pkgsFor genSystems;
      inherit (config) inputs;

      outputs = config.finalOutputs;

      moduleArgs = args // config._module.args // cfg.extra;
    };
  };
}
