{
  config,
  lib,
  conflake',
  ...
}:

let
  inherit (lib)
    mkIf
    mkMerge
    mkOption
    mkOptionDefault
    types
    ;
  inherit (lib.types) lazyAttrsOf nullOr;

  cfg = config.inputs;
in
{
  options = {
    inputs = mkOption {
      type = nullOr (lazyAttrsOf types.raw);
      default = null;
    };

    finalInputs = mkOption {
      internal = true;
      type = lazyAttrsOf types.raw;
    };
  };

  config = mkMerge [
    {
      finalInputs = {
        nixpkgs = mkOptionDefault conflake'.inputs.nixpkgs;
        conflake = mkOptionDefault conflake'.inputs.self;
      };
    }
    (mkIf (cfg != null) {
      finalInputs = cfg;
    })
  ];
}
