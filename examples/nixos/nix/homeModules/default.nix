{
  config,
  lib,
  pkgs,
  inputs',
  ...
}:

{
  home.packages = [
    pkgs.hello
    inputs'.greet.packages.greet
    pkgs.bonjour
  ];
}
