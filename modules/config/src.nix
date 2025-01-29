{
  config,
  lib,
  conflake,
  conflake',
  src,
  ...
}:

let
  inherit (builtins) any isAttrs isPath;
  inherit (lib)
    flip
    hasPrefix
    hasSuffix
    mkOption
    optionalAttrs
    pathIsDirectory
    pipe
    removePrefix
    types
    ;
  inherit (lib.path) subpath;
  inherit (lib.types) functionTo nullOr lazyAttrsOf;

  cfg = config.src;

  get = flip pipe [
    (lib.path.removePrefix src)
    (removePrefix "./")
    subpath.components
    (x: lib.attrByPath x null cfg.tree)
  ];

  has =
    p:
    pipe p [
      (x: src + /${x})
      (x: if hasSuffix "/" p then x else x + /..)
      cfg.get
      (if hasSuffix "/" p then isAttrs else isPath)
    ];
in
{
  options.src = {
    ignore = mkOption {
      type = functionTo types.bool;
      default = { name, type, ... }: type == "directory" && hasPrefix "_" name;
    };
    flake = mkOption {
      internal = true;
      readOnly = true;
      type = nullOr (lazyAttrsOf types.unspecified);
      default = if cfg.has "flake.nix" then import conflake'.flakePath else null;
    };
    get = mkOption {
      internal = true;
      readOnly = true;
      type = functionTo types.unspecified; # unspecified to avoid infinite recursion
      default = get;
    };
    has = mkOption {
      internal = true;
      readOnly = true;
      type = functionTo types.bool;
      default = has;
    };
    relTo = mkOption {
      internal = true;
      readOnly = true;
      type = functionTo types.str;
      default = flip pipe [
        (lib.path.removePrefix src)
        (removePrefix "./")
      ];
    };
    tree = mkOption {
      internal = true;
      readOnly = true;
      type = conflake.types.pathTree;
      default = optionalAttrs (pathIsDirectory src) (
        conflake.collectPaths {
          root = src;
          ignore = args: if cfg.ignore args then true else !(any (f: f args) config.matchers);
        }
      );
    };
  };

  config = {
    matchers = [ src ];
  };
}
