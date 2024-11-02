{ lib, conflake, moduleArgs, ... }:

let
  inherit (lib) mkOption;
  inherit (conflake.types) optCallWith outputs;
in
{
  options = {
    outputs = mkOption {
      type = optCallWith moduleArgs outputs;
      default = { };
    };
  };
}
