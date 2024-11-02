{ config, lib, conflake, genSystems, ... }:

let
  inherit (builtins) isFunction mapAttrs;
  inherit (lib) mkMerge mkOption mkIf;
  inherit (lib.types) lazyAttrsOf;
  inherit (conflake.types) function nullable optFunctionTo;

  wrapBundler = pkgs: bundler: drv:
    if isFunction (bundler (pkgs // drv))
    then bundler pkgs drv
    else bundler drv;
in
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
    (mkIf (config.bundler != null) {
      bundlers.default = config.bundler;
    })

    (mkIf (config.bundlers != null) {
      outputs.bundlers = genSystems (pkgs:
        mapAttrs (_: wrapBundler pkgs) (config.bundlers pkgs));
    })
  ];
}
