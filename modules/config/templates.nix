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
    types
    ;
  inherit (lib.types) lazyAttrsOf;
  inherit (conflake.types) nullable optCallWith template;

  rootConfig = config;
in
{
  options = {
    template = mkOption {
      type = types.unspecified;
      default = null;
    };

    templates = mkOption {
      type = conflake.types.loadable;
      default = { };
    };
  };

  config = mkMerge [
    {
      final =
        { config, ... }:
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
            { inherit (rootConfig) template templates; }

            (mkIf (config.template != null) {
              templates.default = config.template;
            })

            (mkIf (config.templates != { }) {
              outputs = {
                inherit (config) templates;
              };
            })
          ];
        };

      nixDir.loaders."templates.nix" = {
        match = conflake.matchers.file;
        load =
          { src, ... }:
          {
            templates = import src;
          };
      };

      nixDir.loaders."templates".load =
        { src, dirTree, ... }:
        {
          templates = pipe dirTree [
            (filterAttrs (_: isAttrs))
            (mapAttrs (
              name: _: {
                description = mkDefault name;
                path = mkDefault (src + /${name});
              }
            ))
          ];
        };
    }
  ];
}
