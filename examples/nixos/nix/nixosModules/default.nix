{
  config,
  lib,
  pkgs,
  inputs,
  inputs',
  ...
}:

{
  imports = [
    inputs.demo.nixosModules.default
  ];

  environment.systemPackages = [
    pkgs.hello
    pkgs.broken
    inputs'.demo.packages.default
    inputs'.greet.packages.greet
    inputs'.self.packages.bonjour
  ];
}
