{
  config,
  lib,
  conflake,
  moduleArgs,
  ...
}:

let
  inherit (lib) mkOption types;
  inherit (conflake.types) optCallWith outputs;

  cfg = config.outputs;
in
{
  options = {
    outputs = mkOption {
      type = types.unspecified;
      default = { };
    };
  };

  config.final = {
    options = {
      outputs = mkOption {
        type = optCallWith moduleArgs outputs;
        default = { };
      };
    };

    config.outputs = cfg;
  };
}
