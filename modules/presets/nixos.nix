{
  config,
  lib,
  inputs,
  ...
}:

let
  inherit (builtins) mapAttrs;
  inherit (lib)
    mergeAttrs
    mkEnableOption
    mkIf
    mkOption
    mkOptionDefault
    pipe
    types
    ;

  cfg = config.presets.nixos;
in
{
  options.presets.nixos = {
    enable = mkEnableOption "nixos default module" // {
      default = config.presets.enable;
    };

    config = mkEnableOption "inherit config.nixpkgs.config" // {
      default = cfg.enable;
    };

    overlays = mkEnableOption "inherit config.nixpkgs.overlays" // {
      default = cfg.enable;
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

          nixpkgs = {
            config = mkIf cfg.config config.nixpkgs.config;
            overlays = mkIf cfg.overlays config.nixpkgs.overlays;

            hostPlatform = mkOptionDefault "x86_64-linux";
          };
        };
    };
  };
}
