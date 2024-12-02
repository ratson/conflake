{
  config,
  options,
  src,
  lib,
  conflake,
  moduleArgs,
  ...
}:

let
  inherit (builtins)
    attrNames
    filter
    isPath
    ;
  inherit (lib)
    findFirst
    genAttrs
    getAttrFromPath
    hasAttrByPath
    hasSuffix
    mkEnableOption
    mkIf
    mkOption
    optionalAttrs
    path
    pathIsDirectory
    pipe
    removeSuffix
    subtractLists
    ;
  inherit (lib.types)
    attrsOf
    lazyAttrsOf
    listOf
    raw
    str
    submodule
    functionTo
    ;

  cfg = config.nixDir;

  isFileEntry = attrPath: set: hasAttrByPath attrPath set && isPath (getAttrFromPath attrPath set);

  importDir =
    entries:
    genAttrs (pipe entries [
      attrNames
      (filter (hasSuffix ".nix"))
      (map (removeSuffix ".nix"))
    ]) (p: import (if isFileEntry [ "${p}.nix" ] entries then entries."${p}.nix" else entries."${p}"));

  importName =
    name:
    if isFileEntry [ "${name}.nix" ] cfg.entries then
      {
        success = true;
        value = import cfg.entries."${name}.nix";
      }
    else if cfg.entries ? ${name} then
      {
        success = true;
        value = importDir cfg.entries.${name};
      }
    else
      { success = false; };

  importNames = names: findFirst (x: x.success) { success = false; } (map importName names);

  mkModuleLoader = attr: {
    ${config.nixDir.mkLoaderKey attr}.load =
      { src, ... }:
      {
        outputs.${attr} = (conflake.readNixDir src).toAttrs (x: conflake.mkModule x moduleArgs);
      };
  };
in
{
  options = {
    nixDir = mkOption {
      type = submodule {
        options = {
          enable = mkEnableOption "nixDir" // {
            default = true;
          };
          src = mkOption {
            type = conflake.types.path;
            default = src + /nix;
          };
          aliases = mkOption {
            type = attrsOf (listOf str);
            default = { };
          };
          entries = mkOption {
            internal = true;
            readOnly = true;
            type = lazyAttrsOf raw;
            default = optionalAttrs (cfg.enable && pathIsDirectory cfg.src) (config.loadDir cfg.src);
          };
          mkLoaderKey = mkOption {
            internal = true;
            readOnly = true;
            type = functionTo raw;
            default = s: path.removePrefix src (config.nixDir.src + /${s});
          };
          mkModuleLoader = mkOption {
            internal = true;
            readOnly = true;
            type = functionTo raw;
            default = mkModuleLoader;
          };
        };
      };
    };
  };

  config = mkIf (cfg.entries != { }) (
    pipe options [
      attrNames
      (filter (name: !(options.${name}.internal or false)))
      (subtractLists [
        "_module"
        "darwinModules"
        "homeModules"
        "legacyPackages"
        "nixDir"
        "nixosModules"
        "packages"
      ])
      (
        x:
        genAttrs x (
          name:
          let
            val = importNames ([ name ] ++ cfg.aliases.${name} or [ ]);
          in
          mkIf val.success (optionalAttrs val.success val.value)
        )
      )
    ]
  );
}
