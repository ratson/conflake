{
  config,
  lib,
  conflake,
  conflake',
  ...
}:

let
  inherit (lib)
    mkIf
    mkMerge
    mkOption
    mkOptionDefault
    ;
  inherit (lib.types) nullOr;

  cfg = config.inputs;
in
{
  options = {
    inputs = mkOption {
      type = nullOr conflake.types.inputs;
      default = null;
    };

    finalInputs = mkOption {
      internal = true;
      type = conflake.types.inputs;
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
