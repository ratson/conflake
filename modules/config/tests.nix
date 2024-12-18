{ lib, conflake, ... }:

let
  inherit (lib) mkOption;
  inherit (lib.types) lazyAttrsOf;
  inherit (conflake.types) nullable optFunctionTo;
in
{
  options.tests = mkOption {
    type = nullable (optFunctionTo (lazyAttrsOf conflake.types.test));
    default = null;
  };
}
