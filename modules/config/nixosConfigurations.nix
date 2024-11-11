{ config, lib, inputs, conflake, moduleArgs, ... }:

let
  inherit (builtins) mapAttrs;
  inherit (lib) foldl mapAttrsToList mkIf mkOption recursiveUpdate;
  inherit (lib.types) attrs lazyAttrsOf;
  inherit (conflake) selectAttr;
  inherit (conflake.types) optCallWith;

  # Avoid checking if toplevel is a derivation as it causes the nixos modules
  # to be evaluated.
  isNixos = x: x ? config.system.build.toplevel;

  mkNixos = hostname: cfg: inputs.nixpkgs.lib.nixosSystem (cfg // {
    specialArgs = {
      inherit inputs hostname;
      inputs' = mapAttrs (_: selectAttr cfg.system) inputs;
    } // cfg.specialArgs or { };
  });

  configs = mapAttrs
    (hostname: cfg: if isNixos cfg then cfg else mkNixos hostname cfg)
    config.nixosConfigurations;
in
{
  options.nixosConfigurations = mkOption {
    type = optCallWith moduleArgs (lazyAttrsOf (optCallWith moduleArgs attrs));
    default = { };
  };

  config = {
    outputs = mkIf (config.nixosConfigurations != { }) {
      nixosConfigurations = configs;
      checks = foldl recursiveUpdate { } (mapAttrsToList
        (n: v: {
          # Wrapping the drv is needed as computing its name is expensive
          # If not wrapped, it slows down `nix flake show` significantly
          ${v.config.nixpkgs.system}."nixos-${n}" = v.pkgs.runCommand
            "check-nixos-${n}"
            { } "echo ${v.config.system.build.toplevel} > $out";
        })
        configs);
    };
    nixDir.aliases.nixosConfigurations = [ "nixos" ];
  };
}
