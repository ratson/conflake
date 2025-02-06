{
  config,
  lib,
  conflake,
  ...
}:

let
  inherit (lib) mkIf mkOption;
  inherit (lib.types) functionTo raw uniq;
  inherit (conflake.types) nullable;

  cfg = config.functor;
in
{
  options.functor = mkOption {
    type = nullable (uniq (functionTo (functionTo raw)));
    default = null;
  };

  config.outputs = mkIf (cfg != null) (_: {
    __functor = cfg;
  });
}
