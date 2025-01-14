{
  config,
  lib,
  conflake,
  ...
}:

let
  inherit (lib) mkIf mkOption types;
  inherit (lib.types) functionTo raw uniq;
  inherit (conflake.types) nullable;

  cfg = config.functor;
in
{
  options.functor = mkOption {
    type = types.unspecified;
    default = null;
  };

  config.final =
    { config, ... }:
    {
      options.functor = mkOption {
        type = nullable (uniq (functionTo (functionTo raw)));
        default = null;
      };

      config = {
        functor = cfg;

        outputs = mkIf (config.functor != null) (_: {
          __functor = config.functor;
        });
      };
    };
}
