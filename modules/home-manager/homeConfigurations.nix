{ config, lib, inputs, conflake, moduleArgs, ... }:

let
  inherit (builtins) head mapAttrs match;
  inherit (lib) foldl mapAttrsToList mkOption mkIf recursiveUpdate;
  inherit (lib.types) attrs lazyAttrsOf;
  inherit (conflake) selectAttr;
  inherit (conflake.types) optCallWith;

  isHome = x: x ? activationPackage;

  mkHome = name: cfg: inputs.home-manager.lib.homeManagerConfiguration (
    (removeAttrs cfg [ "system" ]) // {
      extraSpecialArgs = {
        inherit inputs;
        inputs' = mapAttrs (_: selectAttr cfg.system) inputs;
      } // cfg.extraSpecialArgs or { };
      modules = [
        ({ lib, ... }: {
          home.username = lib.mkDefault (head (match "([^@]*)(@.*)?" name));
        })
      ] ++ cfg.modules or [ ];
      pkgs = inputs.nixpkgs.legacyPackages.${cfg.system};
    }
  );

  configs = mapAttrs
    (name: cfg: if isHome cfg then cfg else mkHome name cfg)
    config.homeConfigurations;
in
{
  options.homeConfigurations = mkOption {
    type = optCallWith moduleArgs (lazyAttrsOf (optCallWith moduleArgs attrs));
    default = { };
  };

  config = {
    outputs = mkIf (config.homeConfigurations != { }) {
      homeConfigurations = configs;
      checks = foldl recursiveUpdate { } (mapAttrsToList
        (n: v: {
          ${v.config.nixpkgs.system}."home-${n}" = v.activationPackage;
        })
        configs);
    };
    nixDir.aliases.homeConfigurations = [ "home" ];
  };
}
