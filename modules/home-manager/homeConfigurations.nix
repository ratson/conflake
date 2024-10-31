{ config, lib, inputs, ... }:

let
  inherit (lib) head match mkDefault mapAttrs mkIf mkMerge mkOption types;

  mkHmConfig = name: cfg: inputs.home-manager.lib.homeManagerConfiguration (
    let
      username = head (match "([^@]*)(@.*)?" name);
    in
    (removeAttrs cfg [ "system" ] // {
      modules = [
        config.argsModule
        { home.username = mkDefault username; }
      ] ++ cfg.modules or [ ];
      pkgs = inputs.nixpkgs.legacyPackages.${cfg.system};
    })
  );
in
{
  options = {
    homeConfigurations = mkOption {
      type = types.lazyAttrsOf types.raw;
      default = { };
    };
  };

  config = mkMerge [
    (mkIf (config.nixDirEntries ? home) {
      homeConfigurations = mapAttrs
        (name: v: import v)
        config.nixDirEntries.home;
    })

    (mkIf (config.homeConfigurations != { }) {
      outputs = {
        homeConfigurations = mapAttrs
          (hostname: cfg: mkHmConfig hostname cfg)
          config.homeConfigurations;
      };
    })
  ];
}
