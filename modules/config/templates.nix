{
  config,
  lib,
  conflake,
  moduleArgs,
  ...
}:

let
  inherit (builtins) mapAttrs readDir;
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
      type = types.unspecified;
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
    }

    {
      loaders = config.nixDir.mkLoader "templates.nix" (
        { src, ... }:
        {
          templates = import src;
        }
      );
    }

    {
      loaders = config.nixDir.mkLoader "templates" (
        { src, ... }:
        {
          templates = pipe src [
            readDir
            (filterAttrs (_: type: type == "directory"))
            (mapAttrs (
              name: _: {
                description = mkDefault name;
                path = mkDefault (src + /${name});
              }
            ))
          ];
        }
      );
    }
  ];
}
