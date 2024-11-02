# A Conflake module for Conflake module flakes
{ conflake, outputs, src, ... }:

{
  functor = self: self.lib.mkFlake;

  nixDir = src;

  lib.mkFlake = conflake.mkFlake.extend [
    outputs.conflakeModules.default
  ];
}
