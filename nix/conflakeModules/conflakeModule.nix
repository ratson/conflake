# A Conflake module for Conflake module flakes
{ conflake, outputs, src, ... }:

{
  functor = self: self.lib.mkOutputs;

  nixDir = src;

  lib.mkOutputs = conflake.mkOutputs.extend [
    outputs.conflakeModules.default
  ];
}
