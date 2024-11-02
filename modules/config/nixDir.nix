{ config, options, src, lib, conflake, ... }:

let
  inherit (builtins) attrNames attrValues filter foldl' isPath mapAttrs readDir;
  inherit (lib) findFirst flip genAttrs getAttrFromPath hasAttrByPath hasPrefix hasSuffix mkIf mkOption
    nameValuePair pipe remove removePrefix removeSuffix
    optionalAttrs pathIsDirectory subtractLists;
  inherit (lib.types) attrsOf lazyAttrsOf listOf raw str;
  inherit (conflake.types) path;

  inherit (config) nixDirEntries;

  nixDirExists = pathIsDirectory config.nixDir;

  loadDir = dir:
    let
      toEntry = name: type:
        let
          path = dir + /${name};
        in
        if hasPrefix "." path then null
        else if type == "directory" then
          nameValuePair name (loadDir path)
        else if type == "regular" && hasSuffix ".nix" path then
          nameValuePair name path
        else null;
    in
    pipe dir [
      readDir
      (mapAttrs toEntry)
      attrValues
      (remove null)
      (flip foldl' { } (acc: { name, value }:
        acc // { ${name} = value; }))
    ];

  isFileEntry = attrPath: set: hasAttrByPath attrPath set && isPath (getAttrFromPath attrPath set);

  importDir = entries: genAttrs
    (pipe entries [
      attrNames
      (filter (s: s != "default.nix"))
      (filter (s: (hasSuffix ".nix" s)
        || (isFileEntry [ s "default.nix" ] entries)))
      (map (removeSuffix ".nix"))
      (map (removePrefix "_"))
    ])
    (p: import
      (if isFileEntry [ "_${p}.nix" ] entries then entries."_${p}.nix"
      else if isFileEntry [ "${p}.nix" ] entries then entries."${p}.nix"
      else entries."${p}")
    );

  importName = name:
    if isFileEntry [ "${name}.nix" ] nixDirEntries then
      { success = true; value = import nixDirEntries."${name}.nix"; }
    else if isFileEntry [ name "default.nix" ] nixDirEntries then
      { success = true; value = import nixDirEntries.${name}."default.nix"; }
    else if nixDirEntries ? ${name} then
      { success = true; value = importDir nixDirEntries.${name}; }
    else
      { success = false; };

  importNames = names:
    findFirst (x: x.success) { success = false; } (map importName names);
in
{
  options = {
    nixDir = mkOption {
      type = path;
      default = src + /nix;
    };

    nixDirAliases = mkOption {
      type = attrsOf (listOf str);
      default = { };
    };

    nixDirEntries = mkOption {
      type = lazyAttrsOf raw;
      internal = true;
      readOnly = true;
      default = optionalAttrs nixDirExists (loadDir config.nixDir);
    };
  };

  config = mkIf nixDirExists (pipe options [
    attrNames
    (filter (name: ! (options.${name}.internal or false)))
    (subtractLists [ "_module" "nixDir" ])
    (x: genAttrs x (name:
      let
        val = importNames
          (if name == "nixDirAliases" then [ name ] else
          ([ name ] ++ config.nixDirAliases.${name} or [ ]));
      in
      mkIf val.success (optionalAttrs val.success val.value)
    ))
  ]);
}
