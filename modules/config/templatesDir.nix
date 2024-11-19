{ config, src, lib, conflake, ... }:

let
  inherit (builtins) mapAttrs readDir;
  inherit (lib) filterAttrs mkEnableOption mkDefault mkIf mkOption pathIsDirectory pipe types;
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
          src = mkOption {
            type = path;
            default = src + /templates;
          };
        };
      };
      default = { };
    };
  };

  config.templates = mkIf (cfg.enable && pathIsDirectory cfg.src) (
    pipe cfg.src [
      readDir
      (filterAttrs (_: type: type == "directory"))
      (mapAttrs (name: _: {
        path = mkDefault (cfg.src + /${name});
      }))
    ]
  );
}
