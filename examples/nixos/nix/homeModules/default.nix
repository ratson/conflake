{
  pkgs,
  inputs',
  outputs',
  ...
}:

{
  home.packages = [
    pkgs.hello
    inputs'.greet.packages.greet
    outputs'.packages.bonjour
  ];
}
