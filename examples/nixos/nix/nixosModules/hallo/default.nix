{ inputs', ... }:

{
  environment.systemPackages = [
    inputs'.greet.packages.greet
  ];
}
