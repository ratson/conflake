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
    mkDefault
    mkIf
    mkOption
    pipe
    ;
  inherit (lib.types) attrs lazyAttrsOf;
  inherit (conflake.types) optCallWith;

  cfg = config.homeConfigurations;

  isHome = x: x ? activationPackage;
  inherit (config) mkSystemArgs';
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
in
{
  options.homeConfigurations = mkOption {
    type = optCallWith moduleArgs (lazyAttrsOf (optCallWith moduleArgs attrs));
    default = { };
  };

  config = {
    outputs = mkIf (cfg != { }) {
      homeConfigurations = mapAttrs (k: v: if isHome v then v else mkHome k v) cfg;
    };

    nixDir.aliases.homeConfigurations = [ "home" ];
  };
}
