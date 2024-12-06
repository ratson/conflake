{
  config,
  lib,
  conflake,
  pkgsFor,
  ...
}:

let
  inherit (builtins) mapAttrs;
  inherit (lib)
    foldAttrs
    mergeAttrs
    mkOption
    pipe
    types
    ;
in
{
  options.perSystem = mkOption {
    type = types.functionTo conflake.types.outputs;
    default = _: { };
  };

  config.outputs = pipe config.systems [
    (map (
      system:
      pipe pkgsFor.${system} [
        config.perSystem
        (mapAttrs (_: v: { ${system} = v; }))
      ]
    ))
    (foldAttrs mergeAttrs { })
  ];
}
