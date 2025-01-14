{
  config,
  lib,
  conflake,
  ...
}:

let
  inherit (builtins) mapAttrs;
  inherit (lib)
    isFunction
    mkIf
    mkMerge
    mkOption
    types
    ;
  inherit (lib.types) lazyAttrsOf;
  inherit (conflake.types) function nullable optFunctionTo;

  rootConfig = config;

  wrapBundler =
    pkgs: bundler: drv:
    if isFunction (bundler (pkgs // drv)) then bundler pkgs drv else bundler drv;
in
{
  options = {
    bundler = mkOption {
      type = types.unspecified;
      default = null;
    };

    bundlers = mkOption {
      type = types.unspecified;
      default = null;
    };
  };

  config.final =
    { config, ... }:
    {
      options = {
        bundler = mkOption {
          type = nullable function;
          default = null;
        };

        bundlers = mkOption {
          type = nullable (optFunctionTo (lazyAttrsOf function));
          default = null;
        };
      };

      config = mkMerge [
        { inherit (rootConfig) bundler bundlers; }

        (mkIf (config.bundler != null) {
          bundlers.default = config.bundler;
        })

        (mkIf (config.bundlers != null) {
          outputs.bundlers = config.genSystems (pkgs: mapAttrs (_: wrapBundler pkgs) (config.bundlers pkgs));
        })
      ];
    };
}
