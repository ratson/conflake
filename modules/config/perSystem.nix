{
  config,
  lib,
  conflake,
  ...
}:

let
  inherit (builtins) mapAttrs;
  inherit (lib)
    foldAttrs
    mergeAttrs
    mkOption
    pipe
    types
    ;

  rootConfig = config;
in
{
  options.perSystem = mkOption {
    type = types.unspecified;
    default = _: { };
  };

  config.final =
    { config, ... }:
    {
      options.perSystem = mkOption {
        type = types.functionTo conflake.types.outputs;
        default = _: { };
      };

      config = {
        inherit (rootConfig) perSystem;

        outputs = pipe rootConfig.systems [
          (map (
            system:
            pipe config.pkgsFor.${system} [
              config.perSystem
              (mapAttrs (_: v: { ${system} = v; }))
            ]
          ))
          (foldAttrs mergeAttrs { })
        ];
      };
    };
}
