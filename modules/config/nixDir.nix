{
  config,
  lib,
  options,
  conflake,
  mkSystemArgs',
  moduleArgs,
  pkgsFor,
  src,
  ...
}:

let
  inherit (builtins) attrValues isAttrs mapAttrs;
  inherit (lib)
    filterAttrs
    flip
    functionArgs
    genAttrs
    hasSuffix
    mkDefault
    mkEnableOption
    mkMerge
    mkOption
    optionalAttrs
    pipe
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

  mkShallowLoader =
    {
      attr,
      load ? import,
    }:
    {
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
            inherit dirTree load;
            dir = src;
            ignore = { value, ... }: isAttrs value && !(value ? "default.nix");
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
    mkModuleLoaders = mkOption {
      internal = true;
      readOnly = true;
      type = functionTo conflake.types.loaders;
      default = attr: {
        ${attr} = mkShallowLoader {
          inherit attr;
          load = mkModule;
        };
      };
    };
    mkLoaderKey = mkOption {
      internal = true;
      readOnly = true;
      type = functionTo str;
      default = mkLoaderKey;
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

    nixDir.loaders = pipe options [
      (filterAttrs (_: v: (v.type or null) == conflake.types.loadable))
      (mapAttrs (
        attr: _:
        mkDefault (mkShallowLoader {
          inherit attr;
        })
      ))
    ];
  };
}
