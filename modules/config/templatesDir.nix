{ config, src, lib, conflake, ... }:

let
  inherit (builtins) mapAttrs;
  inherit (lib) filterAttrs mkEnableOption mkIf mkOption;
  inherit (lib.types) submodule;
  inherit (conflake.types) path;

  cfg = config.templatesDir;

  templates = filterAttrs (_: v: ! (v ? path)) config.templates;
in
{
  options = {
    templatesDir = mkOption {
      type = submodule {
        options = {
          enable = mkEnableOption "templatesDir" // {
            default = true;
          };
          src = mkOption {
            type = path;
            default = src + /templates;
          };
        };
      };
      default = { };
    };
  };

  config = mkIf (cfg.enable && templates != { }) {
    outputs.templates = mapAttrs
      (k: _: {
        path = cfg.src + /${k};
      })
      templates;
  };
}
