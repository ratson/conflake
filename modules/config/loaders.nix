{
  config,
  lib,
  options,
  conflake,
  conflake',
  mkSystemArgs',
  moduleArgs,
  pkgsFor,
  ...
}:

let
  inherit (builtins)
    isAttrs
    hasAttr
    mapAttrs
    ;
  inherit (lib)
    functionArgs
    hasPrefix
    mkIf
    mkMerge
    mkOption
    pipe
    setDefaultModuleLocation
    setFunctionArgs
    types
    ;
  inherit (lib.types) functionTo lazyAttrsOf;
  inherit (conflake') loadDirWithDefault;

  cfg = config.loaders;

  loadable = conflake'.filterLoadable options;

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
in
{
  options = {
    loaders = mkOption {
      type = lazyAttrsOf (types.listOf conflake.types.loader);
      default = { };
    };

    loaderDefault = mkOption {
      internal = true;
      readOnly = true;
      type = conflake.types.loader;
      default =
        { node, path, ... }:
        loadDirWithDefault {
          ignore = { node, ... }: isAttrs node && !(node ? "default.nix");
          root = path;
          tree = node;
        };
    };

    loaderForModule = mkOption {
      internal = true;
      readOnly = true;
      type = conflake.types.loader;
      default =
        { node, path, ... }:
        loadDirWithDefault {
          ignore = { node, ... }: isAttrs node && !(node ? "default.nix");
          load = mkModule;
          root = path;
          tree = node;
        };
    };

    loadIgnore = mkOption {
      type = functionTo types.bool;
      default = { name, ... }: hasPrefix "_" name;
    };

    matchers = mkOption {
      type = conflake.types.matchers;
      default = [ ];
    };
  };

  config = pipe loadable [
    (mapAttrs (
      attr: _:
      mkIf (hasAttr attr cfg) (
        pipe attr [
          (x: cfg.${x})
          (map (f: f { inherit attr; }))
          mkMerge
        ]
      )
    ))
  ];
}
