{
  config,
  lib,
  inputs,
  outputs,
  ...
}:

outputs.lib.greet (import ./_name.nix)
