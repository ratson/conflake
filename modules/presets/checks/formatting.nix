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
        inputs',
        name,
        pkgs,
        src,
        ...
      }:
      pkgs.runCommandLocal "check-${name}"
        {
          nativeBuildInputs = [
            inputs'.self.formatter
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
