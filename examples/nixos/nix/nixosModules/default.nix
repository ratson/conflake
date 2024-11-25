{
  config,
  lib,
  pkgs,
  inputs',
  ...
}:

{
  environment.systemPackages = [
    pkgs.hello
    inputs'.greet.packages.greet
  ];
}
