{ config, lib, ... }:

let
  inherit (lib) mkEnableOption mkIf;

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
      {
        name,
        outputs',
        pkgs,
        src,
        ...
      }:
      pkgs.runCommandLocal "check-${name}"
        {
          nativeBuildInputs = [
            outputs'.formatter
            pkgs.diffutils
          ];
        }
        ''
          pushd "${src}"
          formatter .
          diff -qr ${src} . | sed 's/Files .* and \(.*\) differ/File \1 not formatted/g'
          popd
          touch $out
        '';
  };
}
