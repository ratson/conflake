{
  config,
  lib,
  conflake,
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
  inherit (lib.types) lazyAttrsOf;
  inherit (conflake.types) devShell nullable;

  cfg = config.devShells;
in
{
  options = {
    devShell = mkOption {
      type = nullable devShell;
      default = null;
    };

    devShells = mkOption {
      type = lazyAttrsOf devShell;
      default = { };
    };
  };

  config = mkMerge [
    (mkIf (config.devShell != null) {
      devShells.default = config.devShell;
    })

    (mkIf (cfg != { }) {
      outputs.devShells = config.genSystems (
        { pkgs, pkgsCall, ... }:
        pipe cfg [
          (mapAttrs (
            _:
            flip pipe [
              pkgsCall
              (
                cfg:
                defaultTo (pipe cfg [
                  (mapAttrs (_: v: if isFunction v then pkgsCall v else v))
                  (
                    cfg':
                    pkgs.mkShell.override { inherit (cfg') stdenv; } (
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
