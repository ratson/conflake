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
    flip
    mergeAttrs
    mkIf
    mkOption
    pipe
    types
    ;
  inherit (lib.attrsets) foldlAttrs;
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
    default = pipe cfg [
      (f: config.genSystems' ({ callWithArgs' }: callWithArgs' f { }))
      (foldlAttrs (
        acc: system:
        flip pipe [
          (mapAttrs (_: v: { ${system} = v; }))
          (mergeAttrs acc)
        ]
      ) { })
    ];
  };

  config = mkIf (options.perSystem.isDefined) {
    outputs = config.perSystemOutputs;
  };
}
