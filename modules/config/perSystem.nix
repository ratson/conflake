{
  config,
  lib,
  options,
  moduleArgs,
  ...
}:

let
  inherit (builtins) attrValues mapAttrs;
  inherit (lib)
    evalModules
    foldAttrs
    genAttrs
    mergeAttrs
    mkIf
    mkOption
    pipe
    types
    ;
  inherit (lib.types) lazyAttrsOf;
  inherit (config) mkSystemArgs;

  cfg = config.perSystem;
in
{
  options.perSystem = mkOption {
    type = types.deferredModuleWith {
      staticModules = [
        (
          { system, ... }:
          {
            freeformType = lazyAttrsOf types.unspecified;

            _module.args = config.pkgsFor.${system} // moduleArgs // mkSystemArgs system;
          }
        )
      ];
    };
    apply =
      module: system:
      (evalModules {
        class = "perSystem";
        modules = [ module ];
        prefix = [
          "perSystem"
          system
        ];
        specialArgs = { inherit system; };
      }).config;
  };

  config = mkIf options.perSystem.isDefined {
    outputs = pipe cfg [
      (genAttrs config.systems)
      (mapAttrs (system: mapAttrs (_: v: { ${system} = v; })))
      attrValues
      (foldAttrs mergeAttrs { })
    ];
  };
}
