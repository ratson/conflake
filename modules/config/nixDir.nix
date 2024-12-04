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
    hasAttr
    isPath
    listToAttrs
    ;
  inherit (lib)
    findFirst
    genAttrs
    getAttrFromPath
    hasAttrByPath
    hasSuffix
    mkEnableOption
    mkOption
    nameValuePair
    path
    pipe
    remove
    removeSuffix
    subtractLists
    ;
  inherit (lib.types)
    lazyAttrsOf
    listOf
    raw
    str
    submodule
    functionTo
    ;

  cfg = config.nixDir;

  isFileEntry = attrPath: set: hasAttrByPath attrPath set && isPath (getAttrFromPath attrPath set);

  hasLoader = name: hasAttr (cfg.mkLoaderKey name) config.loaders;

  importDir =
    entries:
    genAttrs (pipe entries [
      attrNames
      (filter (hasSuffix ".nix"))
      (map (removeSuffix ".nix"))
    ]) (p: import (if isFileEntry [ "${p}.nix" ] entries then entries."${p}.nix" else entries."${p}"));

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
            type = lazyAttrsOf (listOf str);
            default = { };
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

  config = {
    loaders."${cfg.mkLoaderKey "."}".load =
      { src, ... }:
      let
        entries = config.loadDir src;

        importName =
          name:
          if isFileEntry [ "${name}.nix" ] entries then
            {
              success = true;
              value = import entries."${name}.nix";
            }
          else if entries ? ${name} then
            {
              success = true;
              value = importDir entries.${name};
            }
          else
            { success = false; };

        importNames = names: findFirst (x: x.success) { success = false; } (map importName names);

        mkPair =
          name:
          let
            val = importNames ([ name ] ++ cfg.aliases.${name} or [ ]);
          in
          if val.success then nameValuePair name val.value else null;

        invalid = name: !(options.${name}.internal or false) && !hasLoader name;
      in
      pipe options [
        attrNames
        (subtractLists [
          "_module"
          "nixDir"
        ])
        (filter invalid)
        (map mkPair)
        (remove null)
        listToAttrs
      ];
  };
}
