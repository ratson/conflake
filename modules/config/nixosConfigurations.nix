{
  config,
  lib,
  inputs,
  conflake,
  moduleArgs,
  genSystems,
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
    ;
  inherit (lib.types) attrs lazyAttrsOf;
  inherit (conflake) selectAttr;
  inherit (conflake.types) optCallWith;

  # Avoid checking if toplevel is a derivation as it causes the nixos modules
  # to be evaluated.
  isNixos = x: x ? config.system.build.toplevel;

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
        specialArgs = {
          inherit inputs hostname;
          inputs' = mapAttrs (_: selectAttr cfg.system) inputs;
        } // cfg.specialArgs or { };
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
    outputs = mkIf (config.nixosConfigurations != { }) {
      nixosConfigurations = configs;
      checks = genSystems (
        { system, ... }:
        pipe configs [
          (filterAttrs (_: v: v.pkgs.system == system))
          (conflake.withPrefix "nixos-")
          (mapAttrs (
            # Wrapping the drv is needed as computing its name is expensive
            # If not wrapped, it slows down `nix flake show` significantly
            k: v: v.pkgs.runCommand "check-nixos-${k}" { } "echo ${v.config.system.build.toplevel} > $out"
          ))
        ]
      );
    };
    nixDir.aliases.nixosConfigurations = [ "nixos" ];
  };
}
