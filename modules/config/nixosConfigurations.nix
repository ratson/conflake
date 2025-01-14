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
    filterAttrs
    mkDefault
    mkIf
    mkOption
    pipe
    types
    ;
  inherit (lib.types) attrs lazyAttrsOf;
  inherit (conflake.types) optCallWith;

  rootConfig = config;

  # Avoid checking if toplevel is a derivation as it causes the nixos modules
  # to be evaluated.
  isNixos = x: x ? config.system.build.toplevel;
in
{
  options.nixosConfigurations = mkOption {
    type = types.unspecified;
    default = { };
  };

  config = {
    final =
      { config, ... }:
      let
        inherit (config) genSystems mkSystemArgs;
        mkNixos =
          hostname: cfg:
          inputs.nixpkgs.lib.nixosSystem (
            cfg
            // {
              modules = [
                {
                  config.nixpkgs.hostPlatform = mkDefault "x86_64-linux";
                }
              ] ++ cfg.modules or [ ];
              specialArgs =
                {
                  inherit hostname inputs;
                }
                // (mkSystemArgs cfg.system)
                // cfg.specialArgs or { };
            }
          );

        configs = mapAttrs (
          hostname: cfg: if isNixos cfg then cfg else mkNixos hostname cfg
        ) config.nixosConfigurations;
      in
      {
        options.nixosConfigurations = mkOption {
          type = optCallWith moduleArgs (lazyAttrsOf (optCallWith moduleArgs attrs));
          default = { };
        };

        config = {
          inherit (rootConfig) nixosConfigurations;

          outputs = mkIf (config.nixosConfigurations != { }) {
            nixosConfigurations = configs;
            checks = genSystems (
              { system, ... }:
              pipe configs [
                (filterAttrs (_: v: v.pkgs.system == system))
                (conflake.prefixAttrs "nixos-")
                (mapAttrs (
                  # Wrapping the drv is needed as computing its name is expensive
                  # If not wrapped, it slows down `nix flake show` significantly
                  k: v: v.pkgs.runCommand "check-nixos-${k}" { } "echo ${v.config.system.build.toplevel} > $out"
                ))
              ]
            );
          };
        };
      };

    nixDir.aliases.nixosConfigurations = [ "nixos" ];
    loaders = config.nixDir.mkHostLoader "nixosConfigurations";
  };
}
