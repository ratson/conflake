{ inputs', ... }:

{
  environment.systemPackages = [
    inputs'.self.packages.default
  ];
}
