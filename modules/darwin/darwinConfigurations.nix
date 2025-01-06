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
  inherit (lib) mkIf mkOption;
  inherit (lib.types) attrs lazyAttrsOf;
  inherit (conflake.types) optCallWith;

  isDarwin = x: x ? config.system.builder;

  mkDarwin =
    hostname: cfg:
    inputs.nix-darwin.lib.darwinSystem (
      cfg
      // {
        specialArgs =
          {
            inherit hostname inputs;
          }
          // (mkSystemArgs cfg.system)
          // cfg.specialArgs or { };
      }
    );

  configs = mapAttrs (
    hostname: cfg: if isDarwin cfg then cfg else mkDarwin hostname cfg
  ) config.darwinConfigurations;
in
{
  options.darwinConfigurations = mkOption {
    type = optCallWith moduleArgs (lazyAttrsOf (optCallWith moduleArgs attrs));
    default = { };
  };

  config = {
    outputs = mkIf (config.darwinConfigurations != { }) {
      darwinConfigurations = configs;
    };
    nixDir.aliases.darwinConfigurations = [ "darwin" ];
    loaders = config.nixDir.mkHostLoader "darwinConfigurations";
  };
}
