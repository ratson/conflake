{ config, lib, conflake, moduleArgs, ... }:

let
  inherit (builtins) baseNameOf isPath mapAttrs;
  inherit (lib) filterAttrs mkOption mkIf mkMerge types;
  inherit (conflake.types) nullable optCallWith;

  template = types.submodule ({ name, ... }: {
    options = {
      path = mkOption {
        type = types.path // { check = isPath; };
      };
      description = mkOption {
        type = types.str;
        default = baseNameOf config.templates.${name}.path;
      };
      welcomeText = mkOption {
        type = types.nullOr types.lines;
        default = null;
      };
    };
  });
in
{
  options = {
    template = mkOption {
      type = nullable (optCallWith moduleArgs template);
      default = null;
    };

    templates = mkOption {
      type = optCallWith moduleArgs
        (types.lazyAttrsOf (optCallWith moduleArgs template));
      default = { };
      apply = mapAttrs (_: filterAttrs (_: v: v != null));
    };
  };

  config = mkMerge [
    (mkIf (config.template != null) {
      templates.default = config.template;
    })

    (mkIf (config.templates != { }) {
      outputs = { inherit (config) templates; };
    })
  ];
}
