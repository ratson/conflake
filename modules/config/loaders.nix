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
    pipe
    remove
    setAttrByPath
    types
    ;
  inherit (lib.path) subpath;
  inherit (lib.types) functionTo lazyAttrsOf;

  cfg = config.loaders;

  loadDir' =
    f: dir:
    let
      toEntry =
        name: type:
        let
          path = dir + /${name};
        in
        if config.loadIgnore { inherit name path type; } then
          null
        else if type == "directory" then
          nameValuePair name (loadDir' f path)
        else if type == "regular" && hasSuffix ".nix" name then
          f (nameValuePair name path)
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

  loadDir = loadDir' lib.id;

  resolve =
    src: loaders:
    pipe src [
      readDir
      (
        entries:
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
        ]
      )
      attrValues
      (filter (x: x.loader.enable && x.loader.match x.args))
      (map (
        x:
        mkMerge [
          (x.loader.load x.args)
          (mkIf (x.loader.loaders != { }) (resolve x.args.src x.loader.loaders))
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
      type = functionTo (functionTo (lazyAttrsOf types.unspecified));
      default = loadDir';
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

    (mkIf (config.finalLoaders != { } && lib.pathIsDirectory src) {
      loadedOutputs = resolve src config.finalLoaders;
    })

    (pipe options [
      (flip removeAttrs [
        "_module"
        "editorconfig"
        "loaders"
        "loadIgnore"
        "moduleArgs"
        "nixDir"
        "nixpkgs"
        "presets"
        "templatesDir"
        "tests"
      ])
      (filterAttrs (_: v: !(v.internal or false)))
      (mapAttrs (name: _: mkIf (config ? loadedOutputs.${name}) config.loadedOutputs.${name}))
    ])
  ];
}
