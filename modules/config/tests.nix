{ lib, conflake, ... }:

let
  inherit (lib) mkOption;
  inherit (conflake.types) nullable optFunctionTo;
in
{
  options.tests = mkOption {
    type = nullable (optFunctionTo conflake.types.tests);
    default = null;
  };
}
