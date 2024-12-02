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
    attrValues
    filter
    foldl'
    isPath
    mapAttrs
    readDir
    ;
  inherit (lib)
    findFirst
    flip
    genAttrs
    getAttrFromPath
    hasAttrByPath
    hasPrefix
    hasSuffix
    mkEnableOption
    mkIf
    mkOption
    nameValuePair
    optionalAttrs
    path
    pathIsDirectory
    pipe
    remove
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

  loadDir =
    dir:
    let
      toEntry =
        name: type:
        let
          path = dir + /${name};
        in
        if hasPrefix "." name then
          null
        else if type == "directory" then
          nameValuePair name (loadDir path)
        else if type == "regular" && hasSuffix ".nix" name then
          nameValuePair name path
        else
          null;
    in
    pipe dir [
      readDir
      (mapAttrs toEntry)
      attrValues
      (remove null)
      (flip foldl' { } (acc: { name, value }: acc // { ${name} = value; }))
    ];

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
            default = optionalAttrs (cfg.enable && pathIsDirectory cfg.src) (loadDir cfg.src);
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
