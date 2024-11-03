{ config, lib, pkgs, inputs, inputs', ... }:

{
  home.packages = [
    pkgs.hello
    inputs'.greet.packages.greet
  ];
}
