{
  config,
  lib,
  conflake,
  moduleArgs,
  ...
}:

let
  inherit (builtins) isAttrs mapAttrs;
  inherit (lib)
    filterAttrs
    mkDefault
    mkIf
    mkMerge
    mkOption
    pipe
    ;
  inherit (conflake.types) nullable;

  cfg = config.templates;
in
{
  options = {
    template = mkOption {
      type = nullable (conflake.types.template moduleArgs);
      default = null;
    };

    templates = mkOption {
      type = conflake.types.templates moduleArgs;
      default = { };
      apply = mapAttrs (_: filterAttrs (_: v: v != null));
    };
  };

  config = mkMerge [
    (mkIf (config.template != null) {
      templates.default = config.template;
    })

    (mkIf (cfg != { }) {
      outputs.templates = cfg;
    })

    {
      nixDir.loaders.templates =
        {
          node,
          path,
          type,
          ...
        }:
        if type == "regular" then
          import path
        else if type == "directory" then
          pipe node [
            (filterAttrs (_: isAttrs))
            (mapAttrs (
              name: _: {
                description = mkDefault name;
                path = mkDefault (path + /${name});
              }
            ))
          ]
        else
          { };

      nixDir.matchers.templates = conflake.matchers.always;
    }
  ];
}
