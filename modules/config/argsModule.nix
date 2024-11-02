{ config, lib, specialArgs, inputs, conflake, ... }:

let
  inherit (builtins) mapAttrs;
  inherit (lib) genAttrs mkDefault mkOption types;

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
        let
          inputs' = mapAttrs (_: conflake.selectAttr system) config.inputs;
        in
        config._module.args // specialArgs // {
          inherit inputs' pkgs system;

          self' = inputs'.self;
        } // args
      );
    })
    pkgsBySystem;

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
  imports = [ argsModule ];

  options = {
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
