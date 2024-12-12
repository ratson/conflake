{
  config,
  lib,
  conflake,
  genSystems,
  moduleArgs,
  ...
}:

let
  inherit (builtins) mapAttrs;
  inherit (lib)
    functionArgs
    isFunction
    mkIf
    mkMerge
    mkOption
    types
    ;
  inherit (lib.types)
    coercedTo
    lazyAttrsOf
    package
    ;
  inherit (conflake.types)
    function
    nullable
    optCallWith
    optFunctionTo
    ;

  devShellModule = {
    freeformType = lazyAttrsOf (optFunctionTo types.unspecified);

    options = {
      stdenv = mkOption {
        type = optFunctionTo package;
        default = pkgs: pkgs.stdenv;
      };

      overrideShell = mkOption {
        type = nullable package;
        internal = true;
        default = null;
      };
    };
  };

  wrapFn =
    fn: pkgs:
    let
      val = pkgs.callPackage fn { };
    in
    if (functionArgs fn == { }) || !(package.check val) then fn pkgs else val;

  packageOverride = p: { overrideShell = p; };

  devShellType = coercedTo function wrapFn (
    optFunctionTo (coercedTo package packageOverride (types.submodule devShellModule))
  );

  genDevShell =
    pkgs: cfg:
    if cfg.overrideShell != null then
      cfg.overrideShell
    else
      let
        cfg' = mapAttrs (_: v: if isFunction v then v pkgs else v) cfg;
      in
      pkgs.mkShell.override { inherit (cfg') stdenv; } (
        removeAttrs cfg' [
          "overrideShell"
          "stdenv"
        ]
      );
in
{
  options = {
    devShell = mkOption {
      type = nullable devShellType;
      default = null;
    };

    devShells = mkOption {
      type = optCallWith moduleArgs (lazyAttrsOf devShellType);
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
