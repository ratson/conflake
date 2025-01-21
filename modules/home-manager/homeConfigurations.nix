{
  config,
  lib,
  inputs,
  conflake,
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
    types
    ;
  inherit (lib.types) attrs lazyAttrsOf;
  inherit (conflake.types) optCallWith;

  cfg = config.homeConfigurations;

  isHome = x: x ? activationPackage;
in
{
  options.homeConfigurations = mkOption {
    type = types.unspecified;
    default = { };
  };

  config = {
    final =
      { config, ... }:
      let
        inherit (config) genSystems mkSystemArgs';
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
          homeConfigurations = cfg;

          outputs = mkIf (config.homeConfigurations != { }) {
            homeConfigurations = configs;
            checks = genSystems (
              { system, ... }:
              pipe configs [
                (filterAttrs (_: v: v.pkgs.system == system))
                (conflake.prefixAttrs "home-")
                (mapAttrs (_: v: v.activationPackage))
              ]
            );
          };
        };
      };

    nixDir.aliases.homeConfigurations = [ "home" ];
    nixDir.loaders = config.nixDir.mkImportLoaders "homeConfigurations";
  };
}
