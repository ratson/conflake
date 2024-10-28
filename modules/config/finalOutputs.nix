{ config, lib, ... }:

let
  inherit (lib) mkIf mkMerge mkOption types;
in
{
  options = {
    finalOutputs = mkOption {
      type = types.lazyAttrsOf types.raw;
      visible = false;
      readOnly = false;
    };
  };

  config = {
    finalOutputs = mkMerge [
      (mkIf (config.outputs != null) config.outputs)
    ];
  };
}

