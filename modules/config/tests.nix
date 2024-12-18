{
  lib,
  conflake,
  moduleArgs,
  ...
}:

let
  inherit (lib) mkOption;
  inherit (lib.types) lazyAttrsOf;
  inherit (conflake.types) optCallWith;
in
{
  options.tests = mkOption {
    type = optCallWith moduleArgs (lazyAttrsOf conflake.types.test);
    default = { };
  };
}
