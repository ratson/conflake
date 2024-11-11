{ config, lib, conflake, moduleArgs, ... }:

let
  inherit (builtins) isString;
  inherit (lib) mkOption mkOptionType mkIf mkMerge;
  inherit (lib.types) lazyAttrsOf;
  inherit (lib.options) mergeEqualOption;
  inherit (conflake.types) nullable optCallWith;

  template = mkOptionType {
    name = "template";
    description = "template definition";
    descriptionClass = "noun";
    check = x: (x ? description) && (isString x.description) &&
      ((! x ? welcomeText) || (isString x.welcomeText));
    merge = mergeEqualOption;
  };
in
{
  options = {
    template = mkOption {
      type = nullable (optCallWith moduleArgs template);
      default = null;
    };

    templates = mkOption {
      type = optCallWith moduleArgs
        (lazyAttrsOf (optCallWith moduleArgs template));
      default = { };
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
