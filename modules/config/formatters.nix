{
  config,
  src,
  lib,
  conflake,
  genSystems,
  ...
}:

let
  inherit (builtins) all hasContext;
  inherit (lib)
    getExe
    mkDefault
    mkMerge
    mkOption
    mkIf
    mapAttrsToList
    ;
  inherit (lib.types)
    functionTo
    lazyAttrsOf
    package
    str
    ;
  inherit (conflake.types) nullable optFunctionTo;
in
{
  options = {
    formatter = mkOption {
      type = nullable (functionTo package);
      default = null;
    };
    formatters = mkOption {
      type = nullable (optFunctionTo (lazyAttrsOf str));
      default = null;
    };
  };

  config = mkMerge [
    (mkIf (config.formatter != null) {
      outputs.formatter = genSystems config.formatter;
    })

    (mkIf (config.formatters != null) {
      outputs.formatter = mkDefault (
        genSystems (
          {
            pkgs,
            lib,
            fd,
            coreutils,
            ...
          }:
          let
            inherit (lib) attrValues makeBinPath;
            formatters = config.formatters pkgs;
            fullContext = all hasContext (attrValues formatters);
            packages = if config.devShell == null then [ ] else (config.devShell pkgs).packages pkgs;
            caseArms = toString (mapAttrsToList (n: v: "\n      ${n}) ${v} \"$f\" & ;;") formatters);
          in
          pkgs.writeShellScriptBin "formatter" ''
            PATH=${if fullContext then "" else makeBinPath packages}
            for f in "$@"; do
              if [ -d "$f" ]; then
                ${getExe fd} "$f" -Htf -x "$0" &
              else
                case "$(${coreutils}/bin/basename "$f")" in${caseArms}
                esac
              fi
            done &>/dev/null
            wait
          ''
        )
      );
    })

    (mkIf ((config.formatters != null) || (config.formatter != null)) {
      checks.formatting =
        { outputs', diffutils, ... }:
        ''
          ${getExe outputs'.formatter} .
          ${diffutils}/bin/diff -qr ${src} . |\
            sed 's/Files .* and \(.*\) differ/File \1 not formatted/g'
        '';
    })
  ];
}
