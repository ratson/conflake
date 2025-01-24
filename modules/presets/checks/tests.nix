{
  config,
  lib,
  conflake,
  conflake',
  moduleArgs,
  ...
}:

let
  inherit (builtins)
    isAttrs
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
    mkMerge
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
  inherit (conflake) matchers;

  cfg = config.presets.checks.tests;

  tree = config.src.get cfg.src;

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

  mkCheck =
    tests: pkgs:
    let
      testsTree = {
        ${config.src.relTo cfg.src} = tests;
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

  config = mkIf cfg.enable (mkMerge [
    (mkIf (config.tests != null) {
      checks.${cfg.name} = mkDefault (mkCheck testsPlaceholder);
    })

    (mkIf (isAttrs tree) {
      checks.${cfg.name} = pipe cfg.src [
        (root: { inherit root tree; })
        conflake'.loadDir'
        mkCheck
      ];
    })

    { matchers = [ (matchers.mkIn cfg.src) ]; }
  ]);
}
