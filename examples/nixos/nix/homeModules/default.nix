{
  config,
  pkgs,
  inputs,
  inputs',
  outputs,
  outputs',
  ...
}:

{
  imports = [ inputs.self.homeModules.greet ];

  config = {
    home.packages = [
      pkgs.hello
      inputs'.greet.packages.greet
      outputs'.packages.bonjour
      config.greet.finalPackage
    ];
  };
}
