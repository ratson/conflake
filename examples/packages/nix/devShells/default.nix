{ pkgs, inputs', ... }:

pkgs.mkShell {
  packages = [
    pkgs.hello
    inputs'.self.packages.greet
  ];
}
