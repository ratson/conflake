{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options = {
    final = mkOption {
      type = types.submoduleWith { modules = [ ]; };
      default = { };
    };
  };
}
