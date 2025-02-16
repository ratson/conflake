{
  config,
  lib,
  conflake,
  ...
}:

let
  inherit (builtins) dirOf mapAttrs;
  inherit (lib)
    isFunction
    last
    mkIf
    mkMerge
    mkOption
    pipe
    ;
  inherit (lib.path) splitRoot subpath;
  inherit (lib.types) either lazyAttrsOf raw;
  inherit (conflake) callWith;
  inherit (conflake.loaders) loadDirWithDefault;
  inherit (conflake.types) optFunctionTo nullable;

  cfg = config.legacyPackages;

  mkLoad =
    { pkgs, pkgsCall }:
    p:
    let
      isEmacsPackage = pipe p [
        dirOf
        splitRoot
        (x: x.subpath)
        subpath.components
        last
        (x: x == "emacsPackages")
      ];
    in
    if isEmacsPackage then
      pipe p [
        import
        (callWith pkgs.emacsPackages)
        pkgsCall
      ]
    else
      pkgsCall p;
in
{
  options.legacyPackages = mkOption {
    type = nullable (optFunctionTo (lazyAttrsOf (either (lazyAttrsOf raw) raw)));
    default = null;
  };

  config = mkMerge [
    (mkIf (cfg != null) {
      outputs.legacyPackages = config.genSystems (
        {
          pkgs,
          pkgsCall,
          pkgsCall',
          ...
        }:
        pipe cfg [
          pkgsCall
          (mapAttrs (
            k: v:
            if k == "emacsPackages" then
              pipe v [
                (x: if isFunction x then pkgsCall x else x)
                (mapAttrs (
                  _: v:
                  if isFunction v then
                    pipe v [
                      (callWith pkgs.emacsPackages)
                      pkgsCall'
                    ]
                  else
                    v
                ))
              ]
            else
              v
          ))
        ]
      );
    })

    {
      nixDir.loaders.legacyPackages =
        { node, path, ... }:
        { pkgs, pkgsCall, ... }:
        loadDirWithDefault {
          root = path;
          tree = node;
          load = mkLoad { inherit pkgs pkgsCall; };
          mkValue =
            { contexts, ... }:
            pipe contexts [
              (map (x: x.content.value))
              mkMerge
            ];
        };

      nixDir.matchers.legacyPackages = conflake.matchers.always;
    }
  ];
}
