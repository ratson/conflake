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
    hasContext
    ;
  inherit (lib)
    isFunction
    mapAttrs
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
      outputs',
      pkgs,
      pkgsCall,
      ...
    }:
    let
      formatters = pipe config.formatters [
        pkgsCall
        (mapAttrs (_: v: if isFunction v then pkgsCall v else v))
      ];
      fullContext = all hasContext (attrValues formatters);
      caseArms = pipe formatters [
        (mapAttrsToList (k: v: "\n      ${k}) ${v} \"$f\" & ;;"))
        toString
      ];
    in
    pkgs.writeShellApplication {
      name = "formatter";

      runtimeInputs = [
        pkgs.coreutils
        pkgs.fd
      ] ++ (optionals (!fullContext) outputs'.devShells.default.nativeBuildInputs or [ ]);

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
