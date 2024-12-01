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
    mapAttrs
    readDir
    tail
    ;
  inherit (lib)
    attrsToList
    concatMap
    filterAttrs
    hasSuffix
    last
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    partition
    path
    pathIsDirectory
    pathIsRegularFile
    pipe
    setAttrByPath
    ;
  inherit (lib.path) subpath;
  inherit (lib.types)
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
          type = functionTo conflake.types.outputs;
          default = _: { };
        };
        loaders = mkOption {
          type = lazyAttrsOf loader;
          default = { };
        };
      };
    }
  );

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

  mkDirLoader =
    {
      loadName ?
        p:
        pipe p [
          (path.removePrefix src)
          subpath.components
          last
        ],
      loadValue,
    }:
    {
      load =
        { src, ... }:
        {
          ${loadName src} = pipe src [
            readDir
            attrsToList
            (partition ({ name, value }: value == "regular" && hasSuffix ".nix" name))
            (
              x:
              loadValue {
                inherit src;
                filePairs = x.right;
                dirPairs = filter (
                  { name, value }: value == "directory" && pathIsRegularFile (src + /${name}/default.nix)
                ) x.wrong;
              }
            )
          ];
        };
    };
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

    loadedOutputs = mkOption {
      internal = true;
      type = lazyAttrsOf raw;
      default = { };
    };

    mkDirLoader = mkOption {
      internal = true;
      readOnly = true;
      type = functionTo raw;
      default = mkDirLoader;
    };
  };

  config.finalLoaders = pipe config.loaders [
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

  config.loadedOutputs = mkIf (cfg != { } && pathIsDirectory src) (resolve src cfg);
}
