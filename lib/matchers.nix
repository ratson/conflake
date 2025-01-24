{ lib }:

{
  always = _: true;
  dir = { type, ... }: type == "directory";
  file = { type, ... }: type == "regular";

  mkIn = prefix: { path, ... }: lib.path.hasPrefix prefix path;
}
