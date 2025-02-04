{
  config,
  lib,
  conflake,
  ...
}:

let
  inherit (lib)
    mkIf
    mkMerge
    mkOption
    ;
  inherit (conflake.types) nullable;

  cfg = config.apps;
in
{
  options = {
    app = mkOption {
      type = nullable conflake.types.app;
      default = null;
    };

    apps = mkOption {
      type = nullable conflake.types.apps;
      default = null;
    };
  };

  config = mkMerge [
    (mkIf (config.app != null) {
      apps.default = config.app;
    })

    (mkIf (cfg != null) {
      outputs.apps = config.callSystemsWithAttrs cfg;
    })
  ];
}
