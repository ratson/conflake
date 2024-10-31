{ config, lib, inputs, ... }:

let
  isHmConfig = x: x ? activationPackage;

  mkHmConfig = name: cfg: inputs.home-manager.lib.homeManagerConfiguration (
    let
      username = builtins.head (builtins.match "([^@]*)(@.*)?" name);
    in
    (removeAttrs cfg [ "system" ] // {
      modules = [
        config.argsModule
        { home.username = lib.mkDefault username; }
      ] ++ cfg.modules or [ ];
      pkgs = inputs.nixpkgs.legacyPackages.${cfg.system};
    })
  );
in
{
  options = {
    homeConfigurations = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.raw;
      default = { };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (config.nixDirEntries ? home) {
      homeConfigurations = builtins.mapAttrs
        (name: v: import v)
        config.nixDirEntries.home;
    })

    (lib.mkIf (config.homeConfigurations != { }) {
      outputs.homeConfigurations = builtins.mapAttrs
        (hostname: cfg:
          if isHmConfig cfg then cfg
          else mkHmConfig hostname cfg)
        config.homeConfigurations;
    })
  ];
}
