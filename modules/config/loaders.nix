{
  config,
  lib,
  conflake,
  src,
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
    readDir
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
      ...
    }@args:
    pipe dirTree [
      (mapAttrs (
        name: v:
        if isAttrs v then
          nameValuePair name (
            mkDirValue (
              args
              // {
                inherit name;
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
    {
      dir,
      dirTree,
      load,
      ...
    }:
    loadDirTree {
      inherit dir dirTree;
      mkDirValue =
        { dirTree, ... }@args:
        if isPath (dirTree."default.nix" or null) then load dirTree."default.nix" else loadDirTree args;
      mkFilePair = k: v: nameValuePair (removeSuffix ".nix" k) (load v);
    };

  loadDir' =
    {
      root,
      ignore ? config.loadIgnore,
      maxDepth ? null,
      mkPair ? nameValuePair,
      # internal state
      depth ? 0,
      dir ? root,
    }@args:
    let
      toEntry =
        name: type:
        let
          path = dir + /${name};
          skip =
            (type == "directory" && maxDepth != null && depth >= maxDepth)
            || (ignore (args // { inherit name path type; }));
        in
        if skip then
          null
        else if type == "directory" then
          nameValuePair name (
            loadDir' (
              args
              // {
                depth = depth + 1;
                dir = path;
              }
            )
          )
        else if type == "regular" && hasSuffix ".nix" name then
          mkPair name path
        else
          null;
    in
    pipe dir [
      readDir
      (mapAttrs toEntry)
      attrValues
      (remove null)
      listToAttrs
    ];

  loadDir = root: loadDir' { inherit root; };

  loadDirWithDefault =
    {
      load,
      maxDepth ? null,
      ...
    }@args:
    let
      entries = loadDir' (
        {
          mkPair = k: nameValuePair (removeSuffix ".nix" k);
        }
        // (removeAttrs args [ "load" ])
      );
      transform =
        {
          entries,
          depth ? 0,
        }:
        pipe entries [
          (mapAttrs (
            k: v:
            if maxDepth != null && depth + 1 >= maxDepth then
              null
            else if isAttrs v then
              if v ? default && isPath v.default then
                nameValuePair k v.default
              else
                nameValuePair k (transform {
                  entries = v;
                  depth = depth + 1;
                })
            else
              nameValuePair k v
          ))
          attrValues
          (remove null)
          listToAttrs
          (filterAttrs (_: v: v != { }))
        ];
    in
    pipe { inherit entries; } [
      transform
      (lib.mapAttrsRecursive (_: load))
    ];

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
    loadDir = mkOption {
      internal = true;
      readOnly = true;
      type = functionTo (lazyAttrsOf types.unspecified);
      default = loadDir;
    };
    loadDir' = mkOption {
      internal = true;
      readOnly = true;
      type = functionTo (lazyAttrsOf types.unspecified);
      default = loadDir';
    };
    loadDirWithDefault = mkOption {
      internal = true;
      readOnly = true;
      type = functionTo (lazyAttrsOf types.unspecified);
      default = loadDirWithDefault;
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
