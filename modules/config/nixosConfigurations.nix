{ config, lib, inputs, ... }:

let
  isNixos = x: x ? config.system.build.toplevel;

  mkNixos = hostname: cfg: inputs.nixpkgs.lib.nixosSystem (cfg // {
    specialArgs = { inherit hostname; } // cfg.specialArgs or { };
    modules = [ config.argsModule ] ++ cfg.modules or [ ];
  });
in
{
  options = {
    nixosConfigurations = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.raw;
      default = { };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (config.nixDirEntries ? nixos) {
      nixosConfigurations = builtins.mapAttrs
        (_: v: import v)
        config.nixDirEntries.nixos;
    })

    (lib.mkIf (config.nixosConfigurations != { }) {
      outputs.nixosConfigurations = builtins.mapAttrs
        (hostname: cfg:
          if isNixos cfg then cfg
          else mkNixos hostname cfg)
        config.nixosConfigurations;
    })
  ];
}
