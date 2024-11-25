{
  config,
  lib,
  conflake,
  genSystems,
  ...
}:

let
  inherit (lib) mkIf mkOption;
  inherit (lib.types) functionTo pkgs;
  inherit (conflake.types) nullable;
in
{
  options.legacyPackages = mkOption {
    type = nullable (functionTo pkgs);
    default = null;
  };

  config.outputs = mkIf (config.legacyPackages != null) {
    legacyPackages = genSystems config.legacyPackages;
  };
}
