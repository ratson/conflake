{
  config,
  lib,
  conflake,
  ...
}:

let
  inherit (builtins)
    head
    isAttrs
    isList
    listToAttrs
    mapAttrs
    toJSON
    warn
    ;
  inherit (lib)
    flip
    imap0
    mapAttrsRecursive
    mergeAttrs
    mkDefault
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    nameValuePair
    optionalAttrs
    pipe
    runTests
    singleton
    toFunction
    traceIf
    types
    ;
  inherit (lib.generators) toPretty;
  inherit (lib.path) subpath;
  inherit (conflake) matchers prefixAttrsCond;
  inherit (conflake.loaders) loadDir';
  inherit (conflake.debug) isAttrTest mkTestFromList;

  cfg = config.presets.checks.tests;

  tree = config.src.get cfg.src;

  mkSuite = mapAttrs (_: v: if isList v then mkTestFromList v else v);

  placeholder = "flake.nix#tests";
  placeholderTree = optionalAttrs (config.tests != null) {
    ${placeholder} = toFunction config.tests;
  };

  withPrefix =
    attrs: if cfg.prefix != "" then prefixAttrsCond (_: isAttrTest) cfg.prefix attrs else attrs;

  toResult =
    path: cases:
    let
      msgFail = "Unit tests failed: ${toPretty { } cases}\nin ${subpath.join path}";
      msgPass = "Unit tests successful";
    in
    if cases == [ ] then msgPass else warn msgFail cases;

  mkCheck =
    tests:
    { pkgs, pkgsCall }:
    let
      results = pipe placeholderTree [
        (mergeAttrs { ${config.src.relTo cfg.src} = tests; })
        (mapAttrsRecursive (
          _:
          flip pipe [
            pkgsCall
            (
              x:
              if isList x then
                pipe x [
                  (imap0 (i: v: nameValuePair (toString i) [ v ]))
                  listToAttrs
                ]
              else
                singleton x
            )
          ]
        ))
        (mapAttrsRecursive (
          path:
          flip pipe [
            head
            mkSuite
            withPrefix
            (mapAttrs (k: traceIf cfg.trace "${subpath.join path}#${k}"))
            runTests
            (toResult path)
          ]
        ))
        toJSON
      ];
    in
    pkgs.runCommand "check-tests"
      {
        inherit results;
        passAsFile = [ "results" ];
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
    prefix = mkOption {
      type = types.str;
      default = "test-";
    };
    src = mkOption {
      type = types.path;
      default = config.nixDir.src + /tests;
    };
    trace = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf (config.tests != null) {
      checks.${cfg.name} = mkDefault (mkCheck placeholderTree);
    })

    (mkIf (isAttrs tree) {
      checks.${cfg.name} = pipe cfg.src [
        (root: { inherit root tree; })
        loadDir'
        mkCheck
      ];
    })

    { matchers = [ (matchers.mkIn cfg.src) ]; }
  ]);
}
