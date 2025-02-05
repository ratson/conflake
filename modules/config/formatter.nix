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
    ;
  inherit (config) genSystems';
  inherit (conflake.types) nullable;

  cfg = config.formatter;

  mkFormatter =
    {
      coreutils,
      fd,
      stdenv,
      writeShellApplication,
      outputs',
      callWithArgs,
    }:
    let
      inherit (stdenv.hostPlatform) system;
      formatters = callWithArgs config.formatters { };
      fullContext = all hasContext (attrValues formatters);
      caseArms = pipe formatters [
        (mapAttrsToList (k: v: "\n      ${k}) ${v} \"$f\" & ;;"))
        toString
      ];
    in
    writeShellApplication {
      name = "formatter";

      runtimeInputs =
        [ coreutils ]
        ++ (optionals (!elem system [ "x86_64-freebsd" ]) [ fd ])
        ++ (optionals (!fullContext) outputs'.devShells.default.nativeBuildInputs or [ ]);

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
      type = nullable conflake.types.package;
      default = null;
    };
    formatters = mkOption {
      type = nullable conflake.types.formatters;
      default = null;
    };
  };

  config = mkMerge [
    (mkIf (cfg != null) {
      outputs.formatter = genSystems' cfg;
    })

    (mkIf (config.formatters != null) {
      outputs.formatter = pipe mkFormatter [
        genSystems'
        mkDefault
      ];
    })
  ];
}
