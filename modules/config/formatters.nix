{
  config,
  lib,
  conflake,
  ...
}:

let
  inherit (builtins)
    all
    attrValues
    elem
    hasContext
    ;
  inherit (lib)
    mkDefault
    mkMerge
    mkOption
    mkIf
    mapAttrsToList
    optionals
    pipe
    types
    ;
  inherit (lib.types) functionTo lazyAttrsOf;
  inherit (config) genSystems;
  inherit (conflake.types) nullable optFunctionTo;

  mkFormatter =
    pkgs:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
      formatters = config.formatters pkgs;
      fullContext = all hasContext (attrValues formatters);
      packages = optionals (config.devShell != null) (config.devShell pkgs).packages pkgs;
      caseArms = pipe formatters [
        (mapAttrsToList (k: v: "\n      ${k}) ${v} \"$f\" & ;;"))
        toString
      ];
    in
    pkgs.writeShellApplication {
      name = "formatter";

      runtimeInputs =
        [ pkgs.coreutils ]
        ++ (optionals (!elem system [ "x86_64-freebsd" ]) [ pkgs.fd ])
        ++ (optionals (!fullContext) packages);

      text = ''
        for f in "$@"; do
          if [ -d "$f" ]; then
            fd "$f" -Htf -x "$0" &
          else
            case "$(basename "$f")" in${caseArms}
            esac
          fi
        done &>/dev/null
        wait
      '';
    };
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
      outputs.formatter = pipe mkFormatter [
        genSystems
        mkDefault
      ];
    })
  ];
}
