{
  config,
  pkgs,
  inputs,
  inputs',
  outputs',
  ...
}:

let
  broken-packages = [
    # fixed via overlay in flake.nix
    pkgs.broken
    pkgs.broken-deep
    pkgs.broken-here
    outputs'.packages.broken-deep
  ];
in
{
  imports = [ inputs.self.homeModules.greet ];

  config = {
    home.packages = [
      pkgs.hello
      pkgs.bonjour
      inputs'.greet.packages.greet
      outputs'.packages.bonjour
      config.greet.finalPackage
    ] ++ broken-packages;
  };
}
