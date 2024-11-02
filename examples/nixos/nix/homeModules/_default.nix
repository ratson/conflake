{ config, lib, pkgs, ... }:

{
  home.packages = [
    pkgs.hello
  ];
}
