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
  inherit (lib.types) lazyAttrsOf;
  inherit (conflake.types) nullable optCallWith template;
in
{
  options = {
    template = mkOption {
      type = nullable (optCallWith moduleArgs template);
      default = null;
    };

    templates = mkOption {
      type = optCallWith moduleArgs (lazyAttrsOf (optCallWith moduleArgs template));
      default = { };
      apply = mapAttrs (_: filterAttrs (_: v: v != null));
    };
  };

  config = mkMerge [
    (mkIf (config.template != null) {
      templates.default = config.template;
    })

    (mkIf (config.templates != { }) {
      outputs = {
        inherit (config) templates;
      };
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
