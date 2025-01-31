{
  config,
  lib,
  conflake,
  moduleArgs,
  ...
}:

let
  inherit (builtins) mapAttrs;
  inherit (lib)
    defaultTo
    flip
    isFunction
    mkIf
    mkMerge
    mkOption
    pipe
    ;
  inherit (conflake.types) nullable optCallWith;

  cfg = config.devShells;
in
{
  options = {
    devShell = mkOption {
      type = nullable conflake.types.devShell;
      default = null;
    };

    devShells = mkOption {
      type = optCallWith moduleArgs conflake.types.devShells;
      default = { };
    };
  };

  config = mkMerge [
    (mkIf (config.devShell != null) {
      devShells.default = config.devShell;
    })

    (mkIf (config.devShells != { }) {
      outputs.devShells = config.genSystems' (
        { mkShell, callWithArgs }:
        pipe cfg [
          (mapAttrs (
            _:
            flip pipe [
              callWithArgs
              (f: f { })
              (
                cfg:
                defaultTo (pipe cfg [
                  (mapAttrs (_: v: if isFunction v then callWithArgs v { } else v))
                  (
                    cfg':
                    mkShell.override { inherit (cfg') stdenv; } (
                      removeAttrs cfg' [
                        "overrideShell"
                        "stdenv"
                      ]
                    )
                  )
                ]) cfg.overrideShell
              )
            ]
          ))
        ]
      );
    })
  ];
}
