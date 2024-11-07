{ config, lib, inputs, conflake, moduleArgs, ... }:

let
  inherit (builtins) mapAttrs;
  inherit (lib) mkIf mkOption;
  inherit (lib.types) attrs lazyAttrsOf;
  inherit (conflake) selectAttr;
  inherit (conflake.types) optCallWith;

  isDarwin = x: x ? config.system.builder;

  mkDarwin = hostname: cfg: inputs.nix-darwin.lib.darwinSystem (cfg // {
    specialArgs = {
      inherit inputs hostname;
      inputs' = mapAttrs (_: selectAttr cfg.system) inputs;
    } // cfg.specialArgs or { };
    modules = [ config.propagationModule ] ++ cfg.modules or [ ];
  });

  configs = mapAttrs
    (hostname: cfg: if isDarwin cfg then cfg else mkDarwin hostname cfg)
    config.darwinConfigurations;
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
  };
}
