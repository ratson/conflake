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
  inherit (config) inputs outputs;
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
      inherit
        genSystems
        inputs
        mkSystemArgs
        mkSystemArgs'
        outputs
        pkgsFor
        ;

      moduleArgs = args // config._module.args // cfg.extra;
    };
  };
}
