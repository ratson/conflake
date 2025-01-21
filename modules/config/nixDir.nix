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
  inherit (builtins) isAttrs;
  inherit (lib)
    flip
    functionArgs
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

  mkModuleLoader =
    attr:
    mkLoader attr (
      { src, ... }:
      {
        outputs.${attr} = (conflake.readNixDir src).toAttrs mkModule;
      }
    );

  mkHostLoader =
    attr:
    mkMerge (
      map (flip cfg.mkLoader' {
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
      }) ([ attr ] ++ cfg.aliases.${attr} or [ ])
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
    mkHostLoader = mkOption {
      internal = true;
      readOnly = true;
      type = functionTo conflake.types.loaders;
      default = mkHostLoader;
    };
    mkModuleLoader = mkOption {
      internal = true;
      readOnly = true;
      type = functionTo conflake.types.loaders;
      default = mkModuleLoader;
    };
  };
}
