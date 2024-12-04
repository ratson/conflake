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
    mkDefault
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

  mkLoaderKey = s: path.removePrefix src (cfg.src + /${s});

  hasLoader = name: hasAttr (mkLoaderKey name) config.loaders;

  importDir =
    entries:
    genAttrs (pipe entries [
      attrNames
      (filter (hasSuffix ".nix"))
      (map (removeSuffix ".nix"))
    ]) (p: import (if isFileEntry [ "${p}.nix" ] entries then entries."${p}.nix" else entries."${p}"));

  mkLoader = k: load: {
    ${mkLoaderKey k} = {
      inherit load;

      enable = mkDefault cfg.enable;
    };
  };

  mkModuleLoader =
    attr:
    mkLoader attr (
      { src, ... }:
      {
        outputs.${attr} = (conflake.readNixDir src).toAttrs (x: conflake.mkModule x moduleArgs);
      }
    );
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
          mkLoader = mkOption {
            internal = true;
            readOnly = true;
            type = functionTo (functionTo (lazyAttrsOf raw));
            default = mkLoader;
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
    loaders = mkLoader "." (
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
      ]
    );
  };
}
