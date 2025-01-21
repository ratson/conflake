{
  config,
  lib,
  conflake,
  mkSystemArgs',
  moduleArgs,
  pkgsFor,
  src,
  ...
}:

let
  inherit (builtins)
    attrValues
    isAttrs
    listToAttrs
    mapAttrs
    readDir
    ;
  inherit (lib)
    attrsToList
    filter
    flip
    functionArgs
    genAttrs
    hasSuffix
    mkDefault
    mkEnableOption
    mkMerge
    mkOption
    nameValuePair
    optionalAttrs
    partition
    pathIsRegularFile
    pipe
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

  mkLoaderKey = s: config.mkLoaderKey (cfg.src + /${s});

  mkLoader' = k: loader: {
    ${mkLoaderKey k} = {
      enable = mkDefault cfg.enable;
    } // loader;
  };

  mkLoader =
    k: load:
    mkLoader' k (
      {
        inherit load;
      }
      // optionalAttrs (hasSuffix ".nix" k) {
        match = conflake.matchers.file;
      }
    );

  mkModule =
    path:
    let
      f =
        { pkgs, ... }@args:
        conflake.callWith (moduleArgs // config.moduleArgs.extra) path (
          args
          // (mkSystemArgs' pkgs)
          // {
            pkgs = (pkgsFor.${pkgs.stdenv.hostPlatform.system} or { }) // pkgs;
          }
        );
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

  readNixDir =
    src:
    pipe src [
      readDir
      attrsToList
      (partition ({ name, value }: value == "regular" && hasSuffix ".nix" name))
      (x: {
        filePairs = x.right;
        dirPairs = filter (
          { name, value }: value == "directory" && pathIsRegularFile (src + /${name}/default.nix)
        ) x.wrong;
      })
      (args: {
        inherit src;
        inherit (args) dirPairs filePairs;

        toAttrs =
          f:
          pipe args.filePairs [
            (map (x: nameValuePair (removeSuffix ".nix" x.name) (f (src + /${x.name}))))
            (x: x ++ (map (x: x // { value = f (src + /${x.name}); }) args.dirPairs))
            listToAttrs
          ];
      })
    ];

  mkModuleLoader =
    attr:
    mkLoader attr (
      { src, ... }:
      {
        outputs.${attr} = (readNixDir src).toAttrs mkModule;
      }
    );

  mkImportLoaders = attr: {
    ${attr} = {
      collect =
        { dir, ignore, ... }:
        conflake.collectPaths {
          inherit dir ignore;
          maxDepth = 2;
        };
      load =
        { src, dirTree, ... }:
        {
          ${attr} = config.loadDirTreeWithDefault {
            inherit dirTree;
            dir = src;
            load = import;
            ignore = { value, ... }: isAttrs value && !(value ? "default.nix");
          };
        };
    };
  };
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
    loaders = mkOption {
      type = conflake.types.loaders;
      default = { };
    };
    mkImportLoaders = mkOption {
      internal = true;
      readOnly = true;
      type = functionTo conflake.types.loaders;
      default = mkImportLoaders;
    };
    mkLoader' = mkOption {
      internal = true;
      readOnly = true;
      type = functionTo (functionTo conflake.types.loaders);
      default = mkLoader';
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
    loaders = pipe cfg.loaders [
      (mapAttrs (
        k: v:
        pipe cfg.aliases [
          (x: [ k ] ++ (x.${k} or [ ]))
          (map mkLoaderKey)
          (flip genAttrs (
            _:
            {
              inherit (cfg) enable;
            }
            // (optionalAttrs (hasSuffix ".nix" k) {
              match = conflake.matchers.file;
            })
            // v
          ))
        ]
      ))
      attrValues
      mkMerge
    ];
  };
}
