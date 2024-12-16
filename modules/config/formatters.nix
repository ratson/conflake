{
  config,
  lib,
  conflake,
  genSystems,
  ...
}:

let
  inherit (builtins) all attrValues hasContext;
  inherit (lib)
    getExe
    getExe'
    makeBinPath
    mkDefault
    mkMerge
    mkOption
    mkIf
    mapAttrsToList
    optionals
    optionalString
    pipe
    types
    ;
  inherit (lib.types) functionTo lazyAttrsOf;
  inherit (conflake.types) nullable optFunctionTo;

  mkFormatter =
    pkgs:
    let
      formatters = config.formatters pkgs;
      fullContext = all hasContext (attrValues formatters);
      packages = optionals (config.devShell != null) (config.devShell pkgs).packages pkgs;
      caseArms = pipe formatters [
        (mapAttrsToList (k: v: "\n      ${k}) ${v} \"$f\" & ;;"))
        toString
      ];
    in
    pkgs.writeShellScriptBin "formatter" ''
      PATH=${optionalString (!fullContext) (makeBinPath packages)}
      for f in "$@"; do
        if [ -d "$f" ]; then
          ${getExe pkgs.fd} "$f" -Htf -x "$0" &
        else
          case "$(${getExe' pkgs.coreutils "basename"} "$f")" in${caseArms}
          esac
        fi
      done &>/dev/null
      wait
    '';
in
{
  options = {
    formatter = mkOption {
      type = nullable (functionTo types.package);
      default = null;
    };
    formatters = mkOption {
      type = nullable (optFunctionTo (lazyAttrsOf types.str));
      default = null;
    };
  };

  config = mkMerge [
    (mkIf (config.formatter != null) {
      outputs.formatter = genSystems config.formatter;
    })

    (mkIf (config.formatters != null) {
      outputs.formatter = mkDefault (genSystems mkFormatter);
    })
  ];
}
