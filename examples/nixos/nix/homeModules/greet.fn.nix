{ inputs, ... }:
{ config, lib, pkgs, ... }:

{
  home.packages = [
    pkgs.hello
    inputs.greet.packages.${pkgs.system}.greet
  ];
}
