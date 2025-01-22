{
  config,
  lib,
  conflake,
  src,
  options,
  ...
}:

let
  inherit (builtins)
    attrValues
    filter
    hasAttr
    head
    isAttrs
    isPath
    listToAttrs
    mapAttrs
    tail
    ;
  inherit (lib)
    attrsToList
    concatMap
    filterAttrs
    flip
    flatten
    hasPrefix
    hasSuffix
    mkIf
    mkMerge
    mkOption
    nameValuePair
    optionalAttrs
    pathIsDirectory
    pipe
    remove
    removePrefix
    removeSuffix
    setAttrByPath
    types
    ;
  inherit (lib.path) subpath;
  inherit (lib.types) functionTo lazyAttrsOf;

  cfg = config.loaders;

  loadDirTree =
    {
      dir,
      dirTree,
      mkDirValue ? loadDirTree,
      mkFilePair ? nameValuePair,
      ignore ? _: false,
      depth ? 0,
      ...
    }@args:
    pipe dirTree [
      (mapAttrs (
        name: v:
        if
          ignore (
            args
            // {
              inherit name;
              value = v;
            }
          )
        then
          null
        else if isAttrs v then
          nameValuePair name (
            mkDirValue (
              args
              // {
                inherit name;
                depth = depth + 1;
                dir = dir + /${name};
                dirTree = v;
              }
            )
          )
        else if isPath v && hasSuffix ".nix" name then
          mkFilePair name v
        else
          null
      ))
      attrValues
      (remove null)
      listToAttrs
    ];

  loadDirTreeWithDefault =
    { load, ... }@args:
    loadDirTree (
      (removeAttrs args [ "load" ])
      // {
        mkDirValue =
          { dirTree, ... }@args:
          if isPath (dirTree."default.nix" or null) then load dirTree."default.nix" else loadDirTree args;
        mkFilePair = k: v: nameValuePair (removeSuffix ".nix" k) (load v);
      }
    );

  resolve =
    {
      src,
      dirTree,
      loader,
      ...
    }:
    pipe dirTree [
      (filterAttrs (k: _: hasAttr k loader.loaders))
      (mapAttrs (
        name: v: {
          inherit name;
          dirTree = optionalAttrs (isAttrs v) v;
          loader = loader.loaders.${name};
          src = src + /${name};
          type =
            if isAttrs v then
              "directory"
            else if isPath v then
              "regular"
            else
              "unknown";
        }
      ))
      attrValues
      (filter (x: x.loader.enable && x.loader.match x))
      (map (x: [
        (x.loader.load x)
        (mkIf (x.loader.loaders != { }) (resolve x))
      ]))
      flatten
      mkMerge
    ];
in
{
  options = {
    loaders = mkOption {
      type = conflake.types.loaders;
      default = { };
    };

    loadIgnore = mkOption {
      type = functionTo types.bool;
      default =
        {
          loaders ? { },
          name,
          ...
        }:
        !hasAttr name loaders && (hasPrefix "." name || hasPrefix "_" name);
    };

    finalLoaders = mkOption {
      internal = true;
      readOnly = true;
      type = conflake.types.loaders;
    };

    loadDirTree = mkOption {
      internal = true;
      readOnly = true;
      type = functionTo (lazyAttrsOf types.unspecified);
      default = loadDirTree;
    };
    loadDirTreeWithDefault = mkOption {
      internal = true;
      readOnly = true;
      type = functionTo (lazyAttrsOf types.unspecified);
      default = loadDirTreeWithDefault;
    };

    mkLoaderKey = mkOption {
      internal = true;
      readOnly = true;
      type = functionTo types.str;
      default = flip pipe [
        (lib.path.removePrefix src)
        (removePrefix "./")
      ];
    };

    srcLoader = mkOption {
      internal = true;
      readOnly = true;
      type = conflake.types.loader;
      default = {
        loaders = config.finalLoaders;
      };
    };
    srcTree = mkOption {
      internal = true;
      readOnly = true;
      type = conflake.types.pathTree;
      default = optionalAttrs (pathIsDirectory src) (
        config.srcLoader.collect {
          dir = src;
          ignore = config.loadIgnore;
          loaders = config.finalLoaders;
        }
      );
    };
  };

  config = mkMerge [
    {
      finalLoaders = pipe cfg [
        attrsToList
        (map (
          { name, value }:
          let
            parts = subpath.components name;
            loader = pipe parts [
              tail
              (concatMap (x: [ "loaders" ] ++ [ x ]))
              (flip setAttrByPath value)
            ];
          in
          {
            "${head parts}" = loader;
          }
        ))
        mkMerge
      ];
    }

    (mkIf (config.loaders != { } && config.finalLoaders != { } && config.srcTree != { }) {
      final = resolve {
        inherit src;
        dirTree = config.srcTree;
        loader = config.srcLoader;
      };
    })
  ];
}
