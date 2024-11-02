{ config, lib, conflake, moduleArgs, ... }:

let
  inherit (lib) mkOption mkIf;
  inherit (lib.types) attrsOf raw;
  inherit (conflake.types) optCallWith;
in
{
  options.lib = mkOption {
    type = optCallWith moduleArgs (attrsOf raw);
    default = { };
  };

  config.outputs = mkIf (config.lib != { }) {
    inherit (config) lib;
  };
}
