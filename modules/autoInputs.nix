{ lib, src, ... }:

let
  inherit (builtins) mapAttrs pathExists;
  inherit (lib) mkOverride;
  lock2inputs = import ../misc/lock2inputs.nix { inherit lib; };
  lockFound = pathExists (src + "/flake.lock");
  autoInputs = if lockFound then lock2inputs src else { };
in
{
  config.inputs = mapAttrs (_: mkOverride 950) autoInputs;
}
