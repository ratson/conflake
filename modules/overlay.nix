{ config, lib, ... }:

let
  inherit (builtins) mapAttrs warn;
  inherit (lib) mkOrder pipe;
in
{
  config.withOverlays = mkOrder 10 (
    _: prev:
    pipe prev.stdenv.hostPlatform.system [
      (system: config.systemArgsFor.${system})
      (mapAttrs (
        k:
        warn ''
          Usage of `pkgs.${k}` will soon be removed, use `{ pkgs, ${k}, ...}` instead.
          If you have already doing so, ignore this warnning.
        ''
      ))
    ]
  );
}
