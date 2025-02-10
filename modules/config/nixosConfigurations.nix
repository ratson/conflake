{
  config,
  lib,
  inputs,
  conflake,
  moduleArgs,
  ...
}:

let
  inherit (builtins) mapAttrs;
  inherit (lib)
    mergeAttrs
    mkDefault
    mkIf
    mkOption
    ;
  inherit (lib.types) attrs lazyAttrsOf;
  inherit (config) mkSystemArgs;
  inherit (conflake.types) optCallWith;

  cfg = config.nixosConfigurations;

  # Avoid checking if toplevel is a derivation as it causes the nixos modules
  # to be evaluated.
  isNixos = x: x ? config.system.build.toplevel;
in
{
  options.nixosConfigurations = mkOption {
    type = optCallWith moduleArgs (lazyAttrsOf (optCallWith moduleArgs attrs));
    default = { };
  };

  config = {
    outputs = mkIf (cfg != { }) {
      nixosConfigurations = mapAttrs (
        k: v:
        if isNixos v then
          v
        else
          inputs.nixpkgs.lib.nixosSystem (
            mergeAttrs v {
              modules = [
                {
                  config.nixpkgs = mapAttrs (_: mkDefault) {
                    inherit (config.nixpkgs) config overlays;
                    hostPlatform = "x86_64-linux";
                  };
                }
              ] ++ v.modules or [ ];
              specialArgs =
                {
                  inherit inputs;
                  hostname = k;
                }
                // (mkSystemArgs v.system)
                // v.specialArgs or { };
            }
          )
      ) cfg;
    };

    nixDir.aliases.nixosConfigurations = [ "nixos" ];
  };
}
