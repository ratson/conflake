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
    attrNames
    attrValues
    filter
    foldl'
    hasAttr
    head
    mapAttrs
    readDir
    tail
    ;
  inherit (lib)
    attrsToList
    concatMap
    flip
    filterAttrs
    genAttrs
    hasPrefix
    hasSuffix
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    nameValuePair
    pathIsDirectory
    pipe
    remove
    setAttrByPath
    subtractLists
    ;
  inherit (lib.path) subpath;
  inherit (lib.types)
    attrs
    bool
    functionTo
    lazyAttrsOf
    raw
    submodule
    ;

  cfg = config.finalLoaders;

  loader = submodule (
    { name, ... }:
    {
      options = {
        enable = mkEnableOption "${name} loader" // {
          default = true;
        };
        match = mkOption {
          type = functionTo bool;
          default = conflake.matchers.dir;
        };
        load = mkOption {
          type = functionTo (lazyAttrsOf raw);
          default = _: { };
        };
        loaders = mkOption {
          type = lazyAttrsOf loader;
          default = { };
        };
      };
    }
  );

  loadDir' =
    f: dir:
    let
      toEntry =
        name: type:
        let
          path = dir + /${name};
        in
        if hasPrefix "." name then
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
      (flip foldl' { } (acc: { name, value }: acc // { ${name} = value; }))
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
      type = lazyAttrsOf loader;
      default = { };
    };

    finalLoaders = mkOption {
      internal = true;
      readOnly = true;
      type = lazyAttrsOf loader;
    };

    loadDir = mkOption {
      internal = true;
      readOnly = true;
      type = functionTo attrs;
      default = loadDir;
    };
    loadDir' = mkOption {
      internal = true;
      readOnly = true;
      type = functionTo (functionTo attrs);
      default = loadDir';
    };

    loadedOutputs = mkOption {
      internal = true;
      type = submodule {
        freeformType = lazyAttrsOf raw;
        options = {
          inherit (options) outputs;
        };
      };
      default = { };
    };
  };

  config = mkMerge [
    {
      finalLoaders = pipe config.loaders [
        attrsToList
        (map (
          { name, value }:
          let
            parts = subpath.components name;
            loader = pipe parts [
              tail
              (concatMap (x: [ "loaders" ] ++ [ x ]))
              (x: setAttrByPath x value)
            ];
          in
          {
            "${head parts}" = loader;
          }
        ))
        mkMerge
      ];

      loadedOutputs = mkIf (cfg != { } && pathIsDirectory src) (resolve src cfg);
    }

    (pipe options [
      attrNames
      (filter (name: !(options.${name}.internal or false)))
      (subtractLists [
        "_module"
        "conflake"
        "editorconfig"
        "loaders"
        "moduleArgs"
        "nixDir"
        "nixpkgs"
      ])
      (x: genAttrs x (name: mkIf (config ? loadedOutputs.${name}) config.loadedOutputs.${name}))
    ])
  ];
}
