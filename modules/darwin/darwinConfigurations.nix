{
  config,
  lib,
  inputs,
  conflake,
  mkSystemArgs,
  moduleArgs,
  ...
}:

let
  inherit (builtins) mapAttrs;
  inherit (lib) mergeAttrs mkIf mkOption;
  inherit (lib.types) attrs lazyAttrsOf;
  inherit (conflake.types) optCallWith;

  cfg = config.darwinConfigurations;

  isDarwin = x: x ? config.system.builder;
in
{
  options.darwinConfigurations = mkOption {
    type = optCallWith moduleArgs (lazyAttrsOf (optCallWith moduleArgs attrs));
    default = { };
  };

  config = {
    outputs = mkIf (cfg != { }) {
      darwinConfigurations = mapAttrs (
        k: v:
        if isDarwin v then
          v
        else
          inputs.nix-darwin.lib.darwinSystem (
            mergeAttrs v {
              specialArgs =
                {
                  inherit inputs;
                  hostname = k;
                }
                // (mkSystemArgs cfg.system)
                // cfg.specialArgs or { };
            }
          )
      ) cfg;
    };

    nixDir.aliases.darwinConfigurations = [ "darwin" ];
  };
}
