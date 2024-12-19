{
  config,
  options,
  src,
  lib,
  conflake,
  loadBlacklist,
  mkSystemArgs',
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
    filterAttrs
    findFirst
    flip
    functionArgs
    genAttrs
    getAttrFromPath
    hasAttrByPath
    hasSuffix
    mkDefault
    mkEnableOption
    mkOption
    nameValuePair
    optionalAttrs
    pipe
    remove
    removeSuffix
    setDefaultModuleLocation
    setFunctionArgs
    ;
  inherit (lib.types)
    lazyAttrsOf
    listOf
    str
    functionTo
    ;

  cfg = config.nixDir;

  isFileEntry = attrPath: set: hasAttrByPath attrPath set && isPath (getAttrFromPath attrPath set);

  mkLoaderKey = s: config.mkLoaderKey (cfg.src + /${s});

  hasLoader = name: hasAttr (mkLoaderKey name) config.loaders;

  importDir =
    entries:
    genAttrs (pipe entries [
      attrNames
      (filter (hasSuffix ".nix"))
      (map (removeSuffix ".nix"))
    ]) (p: import (if isFileEntry [ "${p}.nix" ] entries then entries."${p}.nix" else entries."${p}"));

  mkLoader = k: load: {
    ${mkLoaderKey k} =
      {
        inherit load;

        enable = mkDefault cfg.enable;
      }
      // optionalAttrs (hasSuffix ".nix" k) {
        match = conflake.matchers.file;
      };
  };

  mkModule =
    path:
    let
      f = conflake.callWith' (
        { pkgs, ... }: moduleArgs // (mkSystemArgs' pkgs) // config.moduleArgs.extra
      ) path;
    in
    if config.moduleArgs.enable then
      pipe f [
        functionArgs
        (x: x // { pkgs = true; })
        (setFunctionArgs f)
        (setDefaultModuleLocation path)
      ]
    else
      path;

  mkModuleLoader =
    attr:
    mkLoader attr (
      { src, ... }:
      {
        outputs.${attr} = (conflake.readNixDir src).toAttrs mkModule;
      }
    );
in
{
  options.nixDir = {
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
      type = functionTo (functionTo conflake.types.loaders);
      default = mkLoader;
    };
    mkLoaderKey = mkOption {
      internal = true;
      readOnly = true;
      type = functionTo str;
      default = mkLoaderKey;
    };
    mkModuleLoader = mkOption {
      internal = true;
      readOnly = true;
      type = functionTo conflake.types.loaders;
      default = mkModuleLoader;
    };
  };

  config = {
    loaders = mkLoader "." (
      { src, ... }:
      let
        entries = config.loadDir' {
          root = src;
          maxDepth = 3;
        };

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
      in
      pipe options [
        (flip removeAttrs conflake.loadBlacklist)
        (filterAttrs (k: v: !(v.internal or false) && !hasLoader k))
        attrNames
        (map mkPair)
        (remove null)
        listToAttrs
      ]
    );
  };
}
