{
  config,
  lib,
  moduleArgs,
  ...
}:

let
  inherit (builtins)
    isList
    length
    mapAttrs
    toFile
    toJSON
    ;
  inherit (lib)
    flip
    head
    last
    mkEnableOption
    mkIf
    mkOption
    pipe
    sublist
    types
    ;
  inherit (lib.generators) toPretty;
  inherit (lib.types) lazyAttrsOf;

  cfg = config.tests;

  mkSuite = mapAttrs (
    k: v:
    if isList v then
      if length v < 2 then
        throw "list should have at least 2 elements: ${k}"
      else
        {
          expr = pipe (head v) (sublist 1 ((length v) - 2) v);
          expected = last v;
        }
    else
      v
  );
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
              path:
              flip pipe [
                (x: if x == null then cfg.cases else pkgs.callPackage x (moduleArgs // cfg.args))
                mkSuite
                lib.runTests
                (
                  cases:
                  if cases == [ ] then
                    "Unit tests successful"
                  else
                    throw "Unit tests failed: ${toPretty { } cases}\nin ${toString path}"
                )
              ]
            ) tests;
          in
          pkgs.runCommandLocal "nix-tests" { } ''
            mkdir $out
            cp ${toFile "test-results.json" (toJSON results)} $out
          '';
      };
  };
}
