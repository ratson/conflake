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
    mkEnableOption
    mkIf
    mkOption
    mkOptionDefault
    optionals
    pipe
    types
    ;
  inherit (lib.types) attrs lazyAttrsOf;
  inherit (conflake.types) optCallWith;

  cfg = config.darwinConfigurations;
  preset = config.presets.darwin;

  isDarwin = x: x ? config.system.builder;
in
{
  options.darwinConfigurations = mkOption {
    type = optCallWith moduleArgs (lazyAttrsOf (optCallWith moduleArgs attrs));
    default = { };
  };

  options.presets.darwin = {
    enable = mkEnableOption "darwin default module" // {
      default = config.presets.enable or false;
    };

    module = mkOption {
      internal = true;
      readOnly = true;
      type = types.deferredModule;
      default =
        { pkgs, ... }:
        {
          _module.args = pipe pkgs.system [
            config.mkSystemArgs
            (mergeAttrs {
              inherit inputs;
            })
            (mapAttrs (_: mkOptionDefault))
          ];

          nixpkgs.hostPlatform = mkOptionDefault "aarch64-darwin";

          system.stateVersion = mkDefault 6;
        };
    };
  };

  config = {
    outputs = mkIf (cfg != { }) {
      darwinConfigurations = mapAttrs (
        k: v:
        if isDarwin v then
          v
        else
          inputs.nix-darwin.lib.darwinSystem (
            mergeAttrs v {
              modules =
                [ { _module.args.hostname = mkOptionDefault k; } ]
                ++ (optionals preset.enable [ preset.module ])
                ++ v.modules or [ ];
            }
          )
      ) cfg;
    };

    nixDir.aliases.darwinConfigurations = [ "darwin" ];
  };
}
