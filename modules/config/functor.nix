{ config, lib, ... }:

let
  inherit (lib) mkOption mkIf;
  inherit (lib.types) functionTo nullOr raw uniq;
in
{
  options = {
    functor = mkOption {
      type = nullOr (uniq (functionTo (functionTo raw)));
      default = null;
    };
  };

  config = mkIf (config.functor != null) {
    outputs.__functor = config.functor;
  };
}
