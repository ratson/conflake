{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  home.packages = [
    pkgs.hello
    inputs.greet.packages.${pkgs.system}.greet
  ];
}
