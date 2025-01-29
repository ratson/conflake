{ lib, conflake, ... }:

let
  inherit (lib) mkOption;
  inherit (conflake.types) nullable optFunctionTo optListOf;
in
{
  options.tests = mkOption {
    type = nullable (optFunctionTo (optListOf conflake.types.tests));
    default = null;
  };
}
