{
  config,
  lib,
  pkgs,
  inputs,
  inputs',
  outputs,
  ...
}:

{
  imports = [
    {
      _module.args.extra-arg2 = 1;
    }
    inputs.demo.nixosModules.default
    outputs.nixosModules.extra
  ];

  environment.systemPackages = [
    pkgs.hello
    pkgs.broken
    inputs'.demo.packages.default
    inputs'.greet.packages.greet
    inputs'.self.packages.bonjour
  ];
}
