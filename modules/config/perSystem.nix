{ config, lib, conflake, genPkgs, ... }:

let
  inherit (lib) attrValues foldAttrs mapAttrs mergeAttrs mkIf mkOption types;
in
{
  options = {
    perSystem = mkOption {
      type = types.nullOr (types.functionTo conflake.types.outputs);
      default = null;
    };
  };

  config = mkIf (config.perSystem != null) {
    outputs = foldAttrs mergeAttrs { } (attrValues (
      genPkgs ({ system, callPackage, ... }:
        mapAttrs (_: v: { ${system} = v; })
          (callPackage config.perSystem { }))
    ));
  };
}
