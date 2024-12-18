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
    toJSON
    ;
  inherit (lib)
    flip
    head
    last
    mapAttrsRecursive
    mkDefault
    mkEnableOption
    mkIf
    mkOption
    optionalAttrs
    pipe
    runTests
    sublist
    toFunction
    types
    ;
  inherit (lib.generators) toPretty;
  inherit (lib.path) subpath;

  cfg = config.presets.checks.tests;

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

  testsPlaceholder = optionalAttrs (config.tests != null) {
    "flake.nix#tests" = null;
  };

  loaderKey = config.mkLoaderKey cfg.src;

  mkCheck =
    tests: pkgs:
    let
      testsTree = {
        ${loaderKey} = tests;
      } // testsPlaceholder;
      results = mapAttrsRecursive (
        path:
        flip pipe [
          (x: if x == null then toFunction config.tests else x)
          (flip pkgs.callPackage moduleArgs)
          mkSuite
          runTests
          (
            cases:
            if cases == [ ] then
              "Unit tests successful"
            else
              lib.trace "Unit tests failed: ${toPretty { } cases}\nin ${subpath.join path}" cases
          )
        ]
      ) testsTree;
    in
    pkgs.runCommandLocal "check-tests"
      {
        passAsFile = [ "results" ];
        results = toJSON results;
      }
      ''
        cp $resultsPath $out
        cat $out | grep -v '{"expected":'
      '';
in
{
  options.presets.checks.tests = {
    enable = mkEnableOption "tests" // {
      default = config.presets.enable;
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
    checks.${cfg.name} = mkDefault (mkCheck testsPlaceholder);

    loaders.${loaderKey}.load =
      { src, ... }:
      {
        checks.${cfg.name} = mkCheck (config.loadDir src);
      };
  };
}
