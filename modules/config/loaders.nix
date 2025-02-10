{
  config,
  lib,
  options,
  conflake,
  moduleArgs,
  ...
}:

let
  inherit (builtins)
    isAttrs
    hasAttr
    mapAttrs
    ;
  inherit (lib)
    flip
    functionArgs
    hasPrefix
    isFunction
    mergeAttrs
    mkIf
    mkMerge
    mkOption
    pipe
    setDefaultModuleLocation
    setFunctionArgs
    types
    ;
  inherit (lib.types) functionTo;
  inherit (config) mkSystemArgs;
  inherit (conflake) callWith;
  inherit (conflake.loaders) filterLoadable loadDirWithDefault;

  cfg = config.loaders;

  loadable = filterLoadable options;

  mkModule =
    path:
    let
      module = import path;
      f =
        { pkgs, ... }@args:
        let
          inherit (pkgs.stdenv.hostPlatform) system;
          pkgs' = config.pkgsFor.${system} // pkgs;
        in
        pipe { pkgs = pkgs'; } [
          (mergeAttrs (mkSystemArgs system))
          (mergeAttrs args)
          (callWith moduleArgs module)
        ];
    in
    if isFunction module then
      pipe f [
        functionArgs
        (flip mergeAttrs { pkgs = false; })
        (setFunctionArgs f)
        (setDefaultModuleLocation path)
        (mergeAttrs { key = path; })
      ]
    else
      path;
in
{
  options = {
    loaders = mkOption {
      type = conflake.types.loaders;
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
