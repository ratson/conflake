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
    optionals
    ;
  inherit (lib.types) attrs lazyAttrsOf;
  inherit (conflake.types) optCallWith;

  cfg = config.nixosConfigurations;
  preset = config.presets.nixos;

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
              modules =
                [ { _module.args.hostname = mkOptionDefault k; } ]
                ++ (optionals (preset.enable or false) [ preset.module ])
                ++ v.modules or [ ];
            }
          )
      ) cfg;
    };

    nixDir.aliases.nixosConfigurations = [ "nixos" ];
  };
}
