{
  config,
  lib,
  conflake,
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
  inherit (conflake) callMustWith;

  cfg = config.perSystem;
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
        pipe cfg [
          (callMustWith config.pkgsFor.${system})
          (callMustWith {
            inherit system;
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
