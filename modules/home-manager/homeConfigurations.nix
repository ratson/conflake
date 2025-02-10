{
  config,
  lib,
  inputs,
  conflake,
  moduleArgs,
  ...
}:

let
  inherit (builtins) hasAttr mapAttrs;
  inherit (lib)
    flip
    mergeAttrs
    mkIf
    mkOption
    mkOptionDefault
    pipe
    ;
  inherit (lib.types) attrs lazyAttrsOf;
  inherit (config) mkSystemArgs;
  inherit (conflake.strings) getUsername;
  inherit (conflake.types) optCallWith;

  cfg = config.homeConfigurations;

  isHome = x: x ? activationPackage;

  mkHome =
    name:
    flip pipe [
      (
        x:
        if (!hasAttr "pkgs" x && hasAttr "system" x) then
          mergeAttrs x {
            pkgs = config.pkgsFor.${x.system};
          }
        else
          x
      )
      (
        x:
        mergeAttrs x {
          modules = [
            (
              { pkgs, ... }:
              {
                _module.args = pipe pkgs.stdenv.hostPlatform.system [
                  mkSystemArgs
                  (mapAttrs (_: mkOptionDefault))
                ];

                home.username = mkOptionDefault (getUsername name);
              }
            )
          ] ++ x.modules or [ ];
        }
      )
      (flip removeAttrs [ "system" ])
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
