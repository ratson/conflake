{ lib, ... }:

let
  inherit (lib) mkOption;
  inherit (lib.types) lazyAttrsOf raw;
in
{
  options = {
    nixpkgs.config = mkOption {
      type = lazyAttrsOf raw;
      default = { };
    };
  };
}
