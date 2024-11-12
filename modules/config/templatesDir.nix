{ config, src, lib, conflake, ... }:

let
  inherit (builtins) mapAttrs pathExists readDir;
  inherit (lib) filterAttrs mkEnableOption mkDefault mkIf mkOption optionalAttrs pipe types;
  inherit (conflake.types) path;

  cfg = config.templatesDir;
in
{
  options = {
    templatesDir = mkOption {
      type = types.submodule {
        options = {
          enable = mkEnableOption "templatesDir" // {
            default = true;
          };
          fromKeys = mkOption {
            type = types.bool;
            default = false;
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

  config = mkIf cfg.enable {
    templates =
      if cfg.fromKeys then
        mapAttrs
          (name: _: {
            path = mkDefault (cfg.src + /${name});
          })
          config.templates
      else
        optionalAttrs (pathExists cfg.src) (pipe
          cfg.src [
          readDir
          (filterAttrs (_: type: type == "directory"))
          (mapAttrs (name: _: {
            path = mkDefault (cfg.src + /${name});
          }))
        ]);
  };
}
