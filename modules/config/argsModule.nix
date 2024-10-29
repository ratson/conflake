{ config, lib, conflake, ... }@args:

let
  inherit (lib) mapAttrs mkDefault mkOption types;
in
{
  options = {
    moduleArgs = mkOption {
      type = types.attrs;
      default = mapAttrs (_: v: mkDefault v) (
        args // { inherit (config) inputs; }
      );
      readOnly = true;
    };

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
        _module.args = config.moduleArgs // (mapAttrs (_: v: mkDefault v) {
          inputs' = mapAttrs (_: conflake.selectAttr system) config.inputs;
        });
      };
  };
}
