{ config, lib, ... }:

let
  templateType = lib.types.submodule {
    freeformType = lib.types.lazyAttrsOf lib.types.raw;

    options = {
      path = lib.mkOption {
        type = lib.types.path;
      };

      description = lib.mkOption {
        type = lib.types.str;
      };
    };
  };
in
{
  options = {
    template = lib.mkOption {
      type = lib.types.nullOr templateType;
      default = null;
    };

    templates = lib.mkOption {
      type = lib.types.lazyAttrsOf templateType;
      default = { };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (config.template != null) {
      templates.default = config.template;
    })

    (lib.mkIf (config.templates != { }) {
      outputs = {
        inherit (config) templates;
      };
    })
  ];
}
