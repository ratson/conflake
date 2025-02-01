{
  config,
  lib,
  conflake,
  inputs,
  outputs,
  ...
}:

let
  inherit (builtins) mapAttrs;
  inherit (lib)
    foldAttrs
    mergeAttrs
    mkOption
    pipe
    ;
  inherit (conflake) callWith;
in
{
  options.perSystem = mkOption {
    type = conflake.types.perSystem;
    default = _: { };
  };

  config = {
    outputs = pipe config.systems [
      (map (
        system:
        pipe config.perSystem [
          (callWith config.pkgsFor.${system})
          (callWith {
            inherit system;
            inherit inputs outputs;
            pkgs = config.pkgsFor.${system};
          })
          (f: f { })
          (mapAttrs (_: v: { ${system} = v; }))
        ]
      ))
      (foldAttrs mergeAttrs { })
    ];
  };
}
