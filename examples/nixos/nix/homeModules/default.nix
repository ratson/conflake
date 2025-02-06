{
  config,
  pkgs,
  inputs,
  inputs',
  outputs',
  ...
}:

{
  imports = [ inputs.self.homeModules.greet ];

  config = {
    home.packages = [
      pkgs.hello
      pkgs.bonjour
      inputs'.greet.packages.greet
      outputs'.packages.bonjour
      config.greet.finalPackage
    ];
  };
}
