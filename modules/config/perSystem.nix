{
  config,
  lib,
  options,
  conflake,
  ...
}:

let
  inherit (builtins) mapAttrs;
  inherit (lib)
    foldAttrs
    mergeAttrs
    mkIf
    mkOption
    pipe
    types
    ;
  inherit (lib.types) lazyAttrsOf;

  cfg = config.perSystem;
in
{
  options.perSystem = mkOption {
    type = conflake.types.perSystem;
    default = _: { };
  };

  options.perSystemOutputs = mkOption {
    internal = true;
    readOnly = true;
    type = lazyAttrsOf (lazyAttrsOf types.unspecified);
    default = pipe config.systems [
      (map (system: config.systemArgsFor'.${system}))
      (map (
        { system, pkgsCall, ... }:
        pipe cfg [
          pkgsCall
          (mapAttrs (_: v: { ${system} = v; }))
        ]
      ))
      (foldAttrs mergeAttrs { })
    ];
  };

  config = mkIf options.perSystem.isDefined {
    outputs = config.perSystemOutputs;
  };
}
