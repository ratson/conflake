{ config, lib, conflake, ... }:

let
  inherit (lib) mkOption types;
in
{
  options = {
    outputs = mkOption {
      type = types.submodule {
        freeformType = conflake.types.outputs;

        config = {
          _module.args = config._module.args;
        };
      };
    };
  };

}

