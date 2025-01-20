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

  collect =
    {
      dir,
      ignore ? config.loadIgnore,
      loaders ? config.finalLoaders,
      ...
    }@args:
    pipe dir [
      readDir
      (
        x:
        mapAttrs (
          name: type:
          let
            path = dir + /${name};
            args' = args // {
              inherit name type;
              dir = path;
              entries = x;
            };
          in
          if ignore args' then
            null
          else if type == "directory" then
            nameValuePair name (optionalAttrs (hasAttr name loaders) (loaders.${name}.collect args'))
          else if type == "regular" then
            nameValuePair name path
          else
            null
        ) x
      )
      attrValues
      (remove null)
      listToAttrs
    ];

  resolve =
    src: entries: loaders:
    pipe entries [
      (filterAttrs (k: _: hasAttr k loaders))
      (mapAttrs (
        name: type: {
          loader = loaders.${name};
          args = {
            inherit entries name type;
            src = src + /${name};
          };
        }
      ))
      attrValues
      (filter (x: x.loader.enable && x.loader.match x.args))
      (map (x: [
        (x.loader.load x.args)
        (mkIf (x.loader.loaders != { }) (
          pipe x.args.src [
            readDir
            (entries: resolve x.args.src entries x.loader.loaders)
          ]
        ))
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
      default = { name, ... }: hasPrefix "." name || hasPrefix "_" name;
    };

    finalLoaders = mkOption {
      internal = true;
      readOnly = true;
      type = conflake.types.loaders;
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

    srcEntries = mkOption {
      internal = true;
      readOnly = true;
      type = lazyAttrsOf types.str;
      default = optionalAttrs (pathIsDirectory src) (readDir src);
    };
    srcTree = mkOption {
      internal = true;
      readOnly = true;
      type = lazyAttrsOf (types.either types.path types.attrs);
      default = optionalAttrs (pathIsDirectory src) (collect {
        dir = src;
      });
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

    (mkIf (config.loaders != { } && config.finalLoaders != { } && config.srcEntries != { }) {
      final = resolve src config.srcEntries config.finalLoaders;
    })
  ];
}
