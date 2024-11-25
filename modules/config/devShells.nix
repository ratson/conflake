{
  config,
  lib,
  conflake,
  genSystems,
  moduleArgs,
  ...
}:

let
  inherit (builtins) functionArgs mapAttrs;
  inherit (lib) mkIf mkMerge mkOption;
  inherit (lib.types)
    coercedTo
    lazyAttrsOf
    lines
    listOf
    package
    str
    submoduleWith
    ;
  inherit (conflake.types)
    function
    nullable
    optCallWith
    optFunctionTo
    ;

  devShellModule.options = {
    inputsFrom = mkOption {
      type = optFunctionTo (listOf package);
      default = [ ];
    };

    packages = mkOption {
      type = optFunctionTo (listOf package);
      default = [ ];
    };

    shellHook = mkOption {
      type = optFunctionTo lines;
      default = "";
    };

    hardeningDisable = mkOption {
      type = listOf str;
      default = [ ];
    };

    env = mkOption {
      type = optFunctionTo (lazyAttrsOf str);
      default = { };
    };

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

  wrapFn =
    fn: pkgs:
    let
      val = pkgs.callPackage fn { };
    in
    if (functionArgs fn == { }) || !(package.check val) then fn pkgs else val;

  packageOverride = p: { overrideShell = p; };

  devShellType = coercedTo function wrapFn (
    optFunctionTo (
      coercedTo package packageOverride (submoduleWith {
        modules = [ devShellModule ];
      })
    )
  );

  genDevShell =
    pkgs: cfg:
    if cfg.overrideShell != null then
      cfg.overrideShell
    else
      let
        cfg' = mapAttrs (_: v: v pkgs) cfg;
      in
      pkgs.mkShell.override { inherit (cfg') stdenv; } (
        cfg'.env
        // {
          inherit (cfg') inputsFrom packages shellHook;
          inherit (cfg) hardeningDisable;
        }
      );
in
{
  options = {
    devShell = mkOption {
      default = null;
      type = nullable devShellType;
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
