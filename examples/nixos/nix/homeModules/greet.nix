{
  config,
  lib,
  pkgs,
  system,
  inputs,
  ...
}:

let
  inherit (lib) mkOption types;

  cfg = config.greet;
in
{
  options.greet = {
    package = mkOption {
      type = types.package;
      default = inputs.greet.packages.${system}.greet;
    };

    finalPackage = mkOption {
      type = types.package;
      readOnly = true;
    };
  };

  config = {
    home.packages = [
      pkgs.hello
    ];

    greet.finalPackage = cfg.package.override { };
  };
}
