{ lib, ... }:

let
  inherit (lib) mkOption;
  inherit (lib.types) lazyAttrsOf raw;
in
{
  options = {
    inputs = mkOption {
      type = lazyAttrsOf raw;
    };
  };
}
