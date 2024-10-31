{ config, lib, inputs, conflake, ... }@args:

let
  inherit (lib) genAttrs mapAttrs mkDefault mkOption types;

  pkgsBySystem = genAttrs config.systems (system:
    import inputs.nixpkgs {
      inherit system;
      overlays = [ config.packagesOverlay ];
    }
  );

  genPkgs = f: mapAttrs
    (system: pkgs: f {
      inherit pkgs system;

      callPackage = f: args: pkgs.callPackage f (
        config._module.args // {
          inherit pkgs system;
          inputs' = mapAttrs (_: conflake.selectAttr system) config.inputs;
        } // args
      );
    })
    pkgsBySystem;

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
in
{
  imports = [ argsModule ];

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
      default = argsModule;
      internal = true;
      readOnly = true;
      description = ''
        Module to provide extra args.
      '';
    };
  };

  config = {
    _module.args = {
      inherit genPkgs pkgsBySystem;
    };
  };
}
