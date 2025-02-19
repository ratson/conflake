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
  inherit (config) genSystems;
  inherit (conflake.types) nullable;

  cfg = config.formatter;

  mkFormatter =
    {
      inputs',
      pkgs,
      pkgsCall,
      ...
    }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
      formatters = pkgsCall config.formatters;
      fullContext = all hasContext (attrValues formatters);
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
        ++ (optionals (!fullContext) inputs'.self.devShells.default.nativeBuildInputs or [ ]);

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
      outputs.formatter = genSystems ({ pkgsCall, ... }: pkgsCall cfg);
    })

    (mkIf (config.formatters != null) {
      outputs.formatter = pipe mkFormatter [
        genSystems
        mkDefault
      ];
    })
  ];
}
