{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options = {
    systems = mkOption {
      type = types.uniq (types.listOf types.nonEmptyStr);
      default = [ "x86_64-linux" "aarch64-linux" ];
    };
  };
}

