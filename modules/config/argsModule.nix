{ config, lib, conflake, ... }:

let
  inherit (builtins) mapAttrs;
  inherit (lib) mkDefault mkOption types;

  argsModule = { inputs, pkgs, ... }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
      inputs' = mapAttrs (_: conflake.selectAttr system) inputs;
    in
    {
      _file = ./argsModule.nix;

      config = {
        _module.args = mapAttrs (_: v: mkDefault v) {
          inherit conflake inputs';
          inherit (config) inputs;

          self = inputs.self;
          self' = inputs'.self;
        };
      };
    };
in
{
  options = {
    argsModule = mkOption {
      type = types.deferredModule;
      default = argsModule;
      internal = true;
      description = ''
        Module to provide extra args.
      '';
    };
  };
}
