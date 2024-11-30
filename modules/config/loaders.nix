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
    mapAttrs
    readDir
    ;
  inherit (lib)
    filterAttrs
    mkOption
    mkIf
    mkEnableOption
    mkMerge
    pathIsDirectory
    pipe
    ;
  inherit (lib.types)
    bool
    functionTo
    lazyAttrsOf
    raw
    submodule
    ;

  cfg = config.loaders;

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
in
{
  options = {
    loaders = mkOption {
      type = lazyAttrsOf loader;
      default = { };
    };

    loadedOutputs = mkOption {
      internal = true;
      type = lazyAttrsOf raw;
      default = { };
    };
  };

  config.loadedOutputs = mkIf (cfg != { } && pathIsDirectory src) (resolve src cfg);
}
