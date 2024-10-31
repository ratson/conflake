{ config, lib, inputs, ... }:

let
  inherit (lib) mapAttrs mkIf mkMerge mkOption types;

  isNixos = x: x ? config.system.build.toplevel;

  mkNixos = hostname: cfg: inputs.nixpkgs.lib.nixosSystem (cfg // {
    specialArgs = { inherit hostname; } // cfg.specialArgs or { };
    modules = [ config.argsModule ] ++ cfg.modules or [ ];
  });
in
{
  options = {
    nixosConfigurations = mkOption {
      type = types.lazyAttrsOf types.raw;
      default = { };
    };
  };

  config = mkMerge [
    (mkIf (config.nixDirEntries ? nixos) {
      nixosConfigurations = mapAttrs
        (_: v: import v)
        config.nixDirEntries.nixos;
    })

    (mkIf (config.nixosConfigurations != { }) {
      outputs = {
        nixosConfigurations = mapAttrs
          (hostname: cfg:
            if isNixos cfg then cfg
            else mkNixos hostname cfg)
          config.nixosConfigurations;
      };
    })
  ];
}
