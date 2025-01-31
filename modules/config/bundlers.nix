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

  wrapBundler =
    { pkgs }:
    bundler: drv: if isFunction (bundler (pkgs // drv)) then bundler pkgs drv else bundler drv;
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
        { callWithArgs }: mapAttrs (_: callWithArgs wrapBundler { }) (callWithArgs cfg { })
      );
    })
  ];
}
