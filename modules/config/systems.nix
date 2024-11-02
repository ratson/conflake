{ lib, ... }:

let
  inherit (lib) mkOption;
  inherit (lib.types) listOf nonEmptyStr uniq;
in
{
  options = {
    systems = mkOption {
      type = uniq (listOf nonEmptyStr);
      default = [ "x86_64-linux" "aarch64-linux" ];
    };
  };
}
