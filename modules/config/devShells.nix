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
    isFunction
    mkIf
    mkMerge
    mkOption
    pipe
    ;
  inherit (config) genSystems;
  inherit (conflake.types) nullable optCallWith;

  genDevShell =
    pkgs: cfg:
    defaultTo (pipe cfg [
      (mapAttrs (_: v: if isFunction v then v pkgs else v))
      (
        cfg':
        pkgs.mkShell.override { inherit (cfg') stdenv; } (
          removeAttrs cfg' [
            "overrideShell"
            "stdenv"
          ]
        )
      )
    ]) cfg.overrideShell;
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
      outputs.devShells = genSystems (pkgs: mapAttrs (_: v: genDevShell pkgs (v pkgs)) config.devShells);
    })
  ];
}
