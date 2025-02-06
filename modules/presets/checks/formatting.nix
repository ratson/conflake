{
  config,
  lib,
  src,
  ...
}:

let
  inherit (lib)
    getExe
    getExe'
    mkEnableOption
    mkIf
    ;

  cfg = config.presets.checks.formatting;
in
{
  options.presets.checks.formatting = {
    enable = mkEnableOption "formatting check" // {
      default = config.presets.checks.enable;
    };
  };

  config = mkIf (cfg.enable && (config.formatters != null) || (config.formatter != null)) {
    checks.formatting =
      { outputs', pkgs, ... }:
      ''
        ${getExe outputs'.formatter} .
        ${getExe' pkgs.diffutils "diff"} -qr ${src} . |\
          sed 's/Files .* and \(.*\) differ/File \1 not formatted/g'
      '';
  };
}
