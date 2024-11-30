{
  config,
  lib,
  conflake,
  moduleArgs,
  src,
  ...
}:

let
  inherit (builtins) readDir;
  inherit (lib)
    concatMap
    filterAttrs
    hasSuffix
    mapAttrs'
    mkIf
    mkMerge
    mkOption
    nameValuePair
    path
    pipe
    removeSuffix
    setAttrByPath
    tail
    ;
  inherit (lib.types) lazyAttrsOf deferredModule;
  inherit (conflake.types) nullable optCallWith;
in
{
  options = {
    nixosModule = mkOption {
      type = nullable deferredModule;
      default = null;
    };

    nixosModules = mkOption {
      type = optCallWith moduleArgs (lazyAttrsOf deferredModule);
      default = { };
    };
  };

  config = mkMerge [
    (mkIf (config.nixosModule != null) {
      nixosModules.default = config.nixosModule;
    })
    (mkIf (config.nixosModules != { }) {
      outputs = {
        inherit (config) nixosModules;
      };
    })
    {
      loaders = pipe config.nixDir.src [
        (path.removePrefix src)
        path.subpath.components
        (x: x ++ [ "nixosModules" ])
        (concatMap (x: [ "loaders" ] ++ [ x ]))
        tail
        (
          x:
          setAttrByPath x {
            load =
              { src, ... }:
              {
                nixosModules = pipe src [
                  readDir
                  (filterAttrs (name: type: type == "regular" && hasSuffix ".nix" name))
                  (mapAttrs' (
                    k: _: nameValuePair (removeSuffix ".nix" k) (conflake.mkModule (src + /${k}) moduleArgs)
                  ))
                ];
              };
          }
        )
      ];
    }
  ];
}
