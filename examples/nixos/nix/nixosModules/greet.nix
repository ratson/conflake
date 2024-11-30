{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  environment.systemPackages = [
    inputs.greet.packages.${pkgs.system}.greet
  ];
}
