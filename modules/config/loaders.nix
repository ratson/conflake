{
  config,
  options,
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
    flip
    filterAttrs
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
    { load, ... }@args:
    let
      entries = loadDir' (
        {
          mkPair = k: nameValuePair (removeSuffix ".nix" k);
        }
        // (removeAttrs args [ "load" ])
      );
      transform = mapAttrs (
        _: v:
        if isAttrs v then
          if v ? default && isPath v.default then load v.default else transform v
        else
          load v
      );
    in
    transform entries;

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
      (map (
        x:
        mkMerge [
          (x.loader.load x.args)
          (mkIf (x.loader.loaders != { }) (resolve x.args.src (readDir x.args.src) x.loader.loaders))
        ]
      ))
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

    loadedOutputs = mkOption {
      internal = true;
      type = lazyAttrsOf types.unspecified;
      default = { };
    };

    mkLoaderKey = mkOption {
      internal = true;
      readOnly = true;
      type = functionTo types.str;
      default = lib.path.removePrefix src;
    };

    srcEntries = mkOption {
      internal = true;
      readOnly = true;
      type = lazyAttrsOf types.str;
      default = optionalAttrs (pathIsDirectory src) (readDir src);
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

    (mkIf (config.finalLoaders != { } && config.srcEntries != { }) {
      loadedOutputs = resolve src config.srcEntries config.finalLoaders;
    })

    (pipe options [
      (flip removeAttrs [
        "_module"
        "loaders"
        "loadIgnore"
        "moduleArgs"
        "nixDir"
        "nixpkgs"
        "presets"
      ])
      (filterAttrs (_: v: !(v.internal or false)))
      (mapAttrs (name: _: mkIf (config ? loadedOutputs.${name}) config.loadedOutputs.${name}))
    ])
  ];
}
