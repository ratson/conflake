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
    ;
  inherit (conflake.types) nullable;

  cfg = config.bundlers;
in
{
  options = {
    bundler = mkOption {
      type = nullable conflake.types.bundler;
      default = null;
    };

    bundlers = mkOption {
      type = nullable conflake.types.bundlers;
      default = null;
    };
  };

  config = mkMerge [
    (mkIf (config.bundler != null) {
      bundlers.default = config.bundler;
    })

    (mkIf (cfg != null) {
      outputs.bundlers = config.genSystems (
        { pkgs, pkgsCall, ... }:
        mapAttrs (
          _: bundler: drv:
          let
            bundler' = if isFunction (bundler (pkgs // drv)) then bundler pkgs else bundler;
          in
          bundler' drv
        ) (pkgsCall cfg)
      );
    })
  ];
}
