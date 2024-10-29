{ config, lib, conflake, ... }:

let
  inherit (lib) mapAttrs mkDefault mkOption types;
in
{
  options = {
    argsModule = mkOption {
      type = types.deferredModule;
      description = ''
        Module to provide extra args.
      '';
      internal = true;
    };
  };

  config = {
    argsModule = { pkgs, ... }:
      let
        inherit (pkgs.stdenv.hostPlatform) system;
      in
      {
        _module.args = mapAttrs (_: v: mkDefault v) {
          inherit conflake;
          inherit (config) inputs;

          inputs' = mapAttrs (_: conflake.selectAttr system) config.inputs;
        };
      };
  };
}
