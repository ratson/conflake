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
    tail
    ;
  inherit (lib)
    concatMap
    filterAttrs
    findFirst
    flip
    genAttrs
    getAttrFromPath
    hasAttrByPath
    hasPrefix
    hasSuffix
    mapAttrs'
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
    setAttrByPath
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

  mkModuleLoader =
    attr:
    pipe config.nixDir.src [
      (path.removePrefix src)
      path.subpath.components
      (x: x ++ [ attr ])
      (concatMap (x: [ "loaders" ] ++ [ x ]))
      tail
      (
        x:
        setAttrByPath (x ++ [ "load" ]) (
          { src, ... }:
          {
            ${attr} = pipe src [
              readDir
              (filterAttrs (name: type: type == "regular" && hasSuffix ".nix" name))
              (mapAttrs' (
                k: _: nameValuePair (removeSuffix ".nix" k) (conflake.mkModule (src + /${k}) moduleArgs)
              ))
            ];
          }
        )
      )
    ];
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
