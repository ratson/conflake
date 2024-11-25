{ lib, inputs, ... }:

let
  inherit (lib) mkOption systems;
  inherit (lib.types)
    coercedTo
    listOf
    nonEmptyStr
    package
    uniq
    ;
in
{
  options = {
    systems = mkOption {
      type = coercedTo package import (uniq (listOf nonEmptyStr));
      default = inputs.systems or systems.flakeExposed;
    };
  };
}
