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
    head
    isAttrs
    isList
    listToAttrs
    mapAttrs
    toJSON
    ;
  inherit (lib)
    flip
    imap0
    mapAttrsRecursive
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
    types
    ;
  inherit (lib.generators) toPretty;
  inherit (lib.path) subpath;
  inherit (conflake) matchers prefixAttrsCond;

  cfg = config.presets.checks.tests;

  tree = config.src.get cfg.src;

  mkSuite = mapAttrs (_: v: if isList v then conflake.types.testVal v else v);

  placeholder = "flake.nix#tests";
  placeholderTree = optionalAttrs (config.tests != null) {
    ${placeholder} = toFunction config.tests;
  };

  withPrefix =
    attrs:
    if cfg.prefix != "" then
      prefixAttrsCond (_: v: v ? "expr" && v ? "expected") cfg.prefix attrs
    else
      attrs;

  mkCheck =
    tests: pkgs:
    let
      results = pipe placeholderTree [
        (x: { ${config.src.relTo cfg.src} = tests; } // x)
        (mapAttrsRecursive (
          _:
          flip pipe [
            (flip pkgs.callPackage moduleArgs)
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
            runTests
            (
              cases:
              if cases == [ ] then
                "Unit tests successful"
              else
                lib.trace "Unit tests failed: ${toPretty { } cases}\nin ${subpath.join path}" cases
            )
          ]
        ))
        toJSON
      ];
    in
    pkgs.runCommandLocal "check-tests"
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
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf (config.tests != null) {
      checks.${cfg.name} = mkDefault (mkCheck placeholderTree);
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
