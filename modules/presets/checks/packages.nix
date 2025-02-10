{ config, lib, ... }:

let
  inherit (builtins) mapAttrs;
  inherit (lib)
    mapAttrs'
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    nameValuePair
    pipe
    types
    ;

  cfg = config.presets.checks.packages;
in
{
  options.presets.checks.packages = {
    enable = mkEnableOption "packages check" // {
      default = config.presets.checks.enable;
    };
    emacs = mkOption {
      type = types.bool;
      default = cfg.enable;
    };
  };

  config = mkMerge [
    (mkIf (cfg.enable && config.packages != null) {
      outputs.checks = pipe config.outputs.packages [
        (mapAttrs (_: mapAttrs' (k: nameValuePair "packages-${k}")))
      ];
    })

    (mkIf (cfg.emacs && config.legacyPackages != null) {
      checks =
        { outputs' }:
        pipe { } [
          (x: outputs'.legacyPackages.emacsPackages or x)
          (mapAttrs' (k: nameValuePair "emacsPackages-${k}"))
        ];
    })
  ];
}
