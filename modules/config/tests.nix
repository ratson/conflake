{
  config,
  lib,
  moduleArgs,
  ...
}:

let
  inherit (builtins) toFile toJSON;
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  inherit (lib.types) lazyAttrsOf;

  cfg = config.tests;
in
{
  options.tests = {
    enable = mkEnableOption "tests" // {
      default = true;
    };
    args = mkOption {
      type = lazyAttrsOf types.raw;
      default = { };
    };
    cases = mkOption {
      type = lazyAttrsOf types.attrs;
      default = { };
    };
    name = mkOption {
      type = types.str;
      default = "tests";
    };
    src = mkOption {
      type = types.path;
      default = config.nixDir.src + /tests;
    };
  };

  config = mkIf cfg.enable {
    loaders.${config.mkLoaderKey cfg.src}.load =
      { src, ... }:
      {
        checks.${cfg.name} =
          pkgs:
          let
            tests = (config.loadDir src) // {
              "tests.cases" = null;
            };
            results = lib.mapAttrsRecursive (
              path: value:
              let
                suite = if value == null then cfg.cases else pkgs.callPackage value (moduleArgs // cfg.args);
                cases = lib.runTests suite;
                result =
                  if cases == [ ] then
                    "Unit tests successful"
                  else
                    throw "Unit tests failed: ${lib.generators.toPretty { } cases}\nin ${toString path} ";
              in
              result
            ) tests;
          in
          pkgs.runCommandLocal "nix-tests" { } ''
            mkdir $out
            cp ${toFile "test-results.json" (toJSON results)} $out
          '';
      };
  };
}
