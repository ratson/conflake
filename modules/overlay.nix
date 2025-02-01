{
  config,
  lib,
  inputs,
  outputs,
  ...
}:

let
  inherit (builtins) mapAttrs warn;
  inherit (lib) mkOrder;
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
        (config.mkSystemArgs' prev)
        // {
          inherit inputs outputs;
        }
      )
  );
}
