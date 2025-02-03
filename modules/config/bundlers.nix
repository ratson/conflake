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
      outputs.bundlers = config.genSystems' (
        { callWithArgs }:
        mapAttrs (
          _: bundler: drv:
          let
            value = callWithArgs bundler drv;
            bundler' = if isFunction value then value else bundler;
          in
          callWithArgs bundler' drv
        ) (callWithArgs cfg { })
      );
    })
  ];
}
