{ config, lib, ... }:

let
  inherit (builtins) mapAttrs;
  inherit (lib)
    filterAttrs
    isDerivation
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
      outputs.checks = mapAttrs (_: mapAttrs' (k: nameValuePair "packages-${k}")) config.outputs.packages;
    })

    (mkIf (cfg.emacs && config.legacyPackages != null) {
      checks =
        { outputs, system }:
        pipe system [
          (x: outputs.legacyPackages.${x}.emacsPackages or { })
          (filterAttrs (_: isDerivation))
          (mapAttrs' (k: nameValuePair "emacsPackages-${k}"))
        ];
    })
  ];
}
