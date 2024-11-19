{ lib, ... }:

let
  inherit (lib) mkOption systems;
  inherit (lib.types) listOf nonEmptyStr uniq;
in
{
  options = {
    systems = mkOption {
      type = uniq (listOf nonEmptyStr);
      default = systems.flakeExposed;
    };
  };
}
