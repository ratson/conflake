{ pkgs, outputs', ... }:

{
  config = {
    home.packages = [
      pkgs.broken
      pkgs.broken-used
      outputs'.packages.broken-used
    ];
  };
}
