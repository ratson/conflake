{
  config,
  lib,
  inputs,
  conflake,
  genSystems,
  mkSystemArgs',
  moduleArgs,
  ...
}:

let
  inherit (builtins)
    hasAttr
    head
    mapAttrs
    match
    ;
  inherit (lib)
    filterAttrs
    mkDefault
    mkIf
    mkOption
    pipe
    ;
  inherit (lib.types) attrs lazyAttrsOf;
  inherit (conflake) withPrefix;
  inherit (conflake.types) optCallWith;

  isHome = x: x ? activationPackage;

  mkHome =
    name: cfg:
    pipe cfg [
      (
        x:
        if (!hasAttr "pkgs" x && hasAttr "system" x) then
          x
          // {
            pkgs = inputs.nixpkgs.legacyPackages.${x.system};
          }
        else
          x
      )
      (
        x:
        x
        // {
          extraSpecialArgs = (mkSystemArgs' x.pkgs) // x.extraSpecialArgs or { };
          modules = [
            {
              home.username = mkDefault (head (match "([^@]*)(@.*)?" name));
            }
          ] ++ x.modules or [ ];
        }
      )
      (x: removeAttrs x [ "system" ])
      inputs.home-manager.lib.homeManagerConfiguration
    ];

  configs = mapAttrs (
    name: cfg: if isHome cfg then cfg else mkHome name cfg
  ) config.homeConfigurations;
in
{
  options.homeConfigurations = mkOption {
    type = optCallWith moduleArgs (lazyAttrsOf (optCallWith moduleArgs attrs));
    default = { };
  };

  config = {
    outputs = mkIf (config.homeConfigurations != { }) {
      homeConfigurations = configs;
      checks = genSystems (
        { system, ... }:
        pipe configs [
          (filterAttrs (_: v: v.pkgs.system == system))
          (withPrefix "home-")
          (mapAttrs (_: v: v.activationPackage))
        ]
      );
    };
    nixDir.aliases.homeConfigurations = [ "home" ];
  };
}
