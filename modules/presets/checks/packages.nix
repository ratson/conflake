{
  config,
  lib,
  conflake,
  ...
}:

let
  inherit (builtins) mapAttrs;
  inherit (lib)
    flip
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    pipe
    types
    ;
  inherit (conflake) prefixAttrs;
  inherit (conflake.loaders) mkPackageCheck;

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
      outputs.checks = mapAttrs (
        system:
        flip pipe [
          (prefixAttrs "packages-")
          (mapAttrs (mkPackageCheck config.pkgsFor.${system}))
        ]
      ) config.outputs.packages;
    })

    (mkIf (cfg.emacs && config.legacyPackages != null) {
      outputs.checks = mapAttrs (
        system:
        flip pipe [
          (x: x.emacsPackages)
          (prefixAttrs "emacsPackages-")
          (mapAttrs (mkPackageCheck config.pkgsFor.${system}))
        ]
      ) config.outputs.legacyPackages;
    })
  ];
}
