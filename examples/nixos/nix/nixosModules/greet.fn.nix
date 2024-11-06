{ inputs, ... }:
{ config, lib, pkgs, ... }:

{
  environment.systemPackages = [
    inputs.greet.packages.${pkgs.system}.greet
  ];
}
