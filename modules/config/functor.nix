{
  config,
  lib,
  conflake,
  ...
}:

let
  inherit (lib) mkOption mkIf;
  inherit (lib.types) functionTo raw uniq;
  inherit (conflake.types) nullable;
in
{
  options.functor = mkOption {
    type = nullable (uniq (functionTo (functionTo raw)));
    default = null;
  };

  config.outputs = mkIf (config.functor != null) (_: {
    __functor = config.functor;
  });
}
