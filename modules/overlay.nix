{
  config,
  src,
  lib,
  inputs,
  conflake,
  moduleArgs,
  outputs,
  ...
}:

let
  inherit (builtins) mapAttrs warn;
  inherit (lib) mkOrder;
  inherit (config) mkSystemArgs';
in
{
  config.withOverlays = mkOrder 10 (
    _: prev:
    (mapAttrs (
      k:
      warn ''
        Usage of `pkgs.${k}` will soon be removed, use `{ pkgs, ${k}, ...}` instead.
        If you have already doing so, ignore this warnning.
      ''
    ))
      (
        (mkSystemArgs' prev)
        // {
          inherit
            conflake
            inputs
            moduleArgs
            outputs
            src
            ;
          inherit (config) defaultMeta;
          inherit (prev.stdenv.hostPlatform) system;
        }
      )
  );
}
