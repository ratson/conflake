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
    mkIf
    mkOption
    mkOptionDefault
    pipe
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
                (
                  { pkgs, ... }:
                  {
                    _module.args = pipe v.system [
                      mkSystemArgs
                      (mergeAttrs {
                        inherit inputs;
                        hostname = k;
                      })
                      (mapAttrs (_: mkOptionDefault))
                    ];

                    nixpkgs = mapAttrs (_: mkOptionDefault) {
                      inherit (config.nixpkgs) config overlays;
                      hostPlatform = "x86_64-linux";
                    };
                  }
                )
              ] ++ v.modules or [ ];
            }
          )
      ) cfg;
    };

    nixDir.aliases.nixosConfigurations = [ "nixos" ];
  };
}
