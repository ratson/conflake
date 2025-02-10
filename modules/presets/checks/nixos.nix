{
  config,
  lib,
  conflake,
  ...
}:

let
  inherit (builtins) mapAttrs;
  inherit (lib)
    filterAttrs
    mkEnableOption
    mkIf
    pipe
    ;
  inherit (conflake) prefixAttrs;

  cfg = config.presets.checks.nixos;
in
{
  options.presets.checks.nixos = {
    enable = mkEnableOption "nixos configuration check" // {
      default = config.presets.checks.enable;
    };
  };

  config = mkIf (cfg.enable && config.nixosConfigurations != { }) {
    outputs.checks = config.genSystems (
      { system, ... }:
      pipe config.outputs.nixosConfigurations [
        (filterAttrs (_: v: v.pkgs.system == system))
        (prefixAttrs "nixos-")
        (mapAttrs (
          # Wrapping the drv is needed as computing its name is expensive
          # If not wrapped, it slows down `nix flake show` significantly
          k: v:
          v.pkgs.runCommandLocal "check-nixos-${k}" { } ''
            echo ${v.config.system.build.toplevel} > $out
          ''
        ))
      ]
    );
  };
}
