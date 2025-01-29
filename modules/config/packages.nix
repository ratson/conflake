{
  config,
  lib,
  inputs,
  conflake,
  conflake',
  moduleArgs,
  src,
  ...
}:

let
  inherit (builtins)
    hasAttr
    mapAttrs
    parseDrvName
    tryEval
    warn
    ;
  inherit (lib)
    defaultTo
    filterAttrs
    findFirst
    flip
    functionArgs
    mergeAttrs
    mkIf
    mkMerge
    mkOption
    optionalAttrs
    optionals
    pipe
    ;
  inherit (lib.types) lazyAttrsOf str uniq;
  inherit (conflake.types)
    nullable
    optFunctionTo
    overlay
    packageDef
    ;

  genPkg =
    final: prev: name: pkg:
    let
      args = functionArgs pkg;
      noArgs = args == { };
      pkg' = if noArgs then { pkgs }: pkg pkgs else pkg;
      dependsOnSelf = hasAttr name args;
      dependsOnPkgs = noArgs || (args ? pkgs);
      selfOverride = {
        ${name} = prev.${name} or (throw "${name} depends on ${name}, but no existing ${name}.");
      };
      overrides =
        filterAttrs (k: _: hasAttr k args) moduleArgs
        // optionalAttrs dependsOnSelf selfOverride
        // optionalAttrs dependsOnPkgs { pkgs = final.pkgs // selfOverride; };
    in
    final.callPackage pkg' overrides;
  genPkgs =
    final: prev: pkgs:
    mapAttrs (name: genPkg final prev name) pkgs;

  getPkgDefs = pkgs: config.packages (moduleArgs // { inherit (pkgs) system; });

  packages = config.genSystems (pkgs: mapAttrs (k: _: pkgs.${k}) (getPkgDefs pkgs));
in
{
  options = {
    package = mkOption {
      type = nullable packageDef;
      default = null;
    };

    packages = mkOption {
      type = nullable (optFunctionTo (lazyAttrsOf packageDef));
      default = null;
    };

    pname = mkOption {
      type = nullable str;
      default = null;
    };

    packageOverlay = mkOption {
      internal = true;
      type = uniq overlay;
      default = _: _: { };
    };
  };

  config = mkMerge [
    (mkIf (config.package != null) {
      packages.default = config.package;
    })

    (mkIf (config.packages != null) {
      packageOverlay =
        final: prev:
        let
          pkgDefs = getPkgDefs prev;
          getName = pkg: pkg.pname or (parseDrvName pkg.name).name;
          mockPkgs = conflake'.nameMockedPkgs prev;

          defaultPkgName = flip defaultTo config.pname (
            findFirst (x: (tryEval x).success)
              (throw (
                "Could not determine the name of the default package; "
                + "please set the `pname` conflake option to the intended name."
              ))
              [
                (getName (mockPkgs.callPackage pkgDefs.default { }))
                (getName
                  (import inputs.nixpkgs {
                    inherit (prev.stdenv.hostPlatform) system;
                    inherit (config.nixpkgs) config;
                    overlays =
                      warn ''
                        Getting default package name with overlays will be removed
                        due to the performance cost on nixpkgs re-evaluation and
                        may cause infinite recursion.
                        Set `pname` explicitly to stop this in ${src}/flake.nix
                      '' config.withOverlays
                      ++ [
                        (final: prev: genPkgs final prev pkgDefs)
                      ];
                  }).default
                )
              ]
          );
          default = genPkg final prev defaultPkgName pkgDefs.default;
        in
        pipe pkgDefs [
          (flip removeAttrs [ "default" ])
          (genPkgs final prev)
          (mergeAttrs (
            optionalAttrs (pkgDefs ? default) {
              inherit default;
              ${defaultPkgName} = warn ''
                Auto derive package name from default package will soon be
                removed.
                Package `${defaultPkgName}` should be exported explicitly.
              '' default;
            }
          ))
        ];

      outputs = { inherit packages; };

      devShell.inputsFrom =
        pkgs:
        pipe pkgs [
          getPkgDefs
          (hasAttr "default")
          (flip optionals [ pkgs.default ])
        ];
    })
  ];
}
