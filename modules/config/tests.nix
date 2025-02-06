{ lib, conflake, ... }:

let
  inherit (lib) mkOption;
  inherit (conflake.types) nullable;
in
{
  options.tests = mkOption {
    type = nullable conflake.types.tests;
    default = null;
  };
}
