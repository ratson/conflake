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
    isList
    hasAttr
    mapAttrs
    parseDrvName
    tryEval
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
    removeAttrs
    types
    ;
  inherit (lib.types)
    lazyAttrsOf
    listOf
    oneOf
    str
    uniq
    ;
  inherit (conflake) callWith;
  inherit (conflake.types) nullable overlay;

  cfg = config.packages;

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

  getPkgDefs = pkgs: cfg (moduleArgs // { inherit (pkgs) system; });
in
{
  options = {
    package = mkOption {
      type = nullable conflake.types.package;
      default = null;
    };

    packages = mkOption {
      type = nullable conflake.types.packages;
      default = null;
    };

    pname = mkOption {
      type = nullable str;
      default = null;
    };
    description = mkOption {
      type = nullable str;
      default = config.src.flake.description or null;
    };
    license = mkOption {
      type = nullable (oneOf [
        str
        (listOf str)
      ]);
      default = null;
    };

    defaultMeta = mkOption {
      internal = true;
      readOnly = true;
      type = types.unspecified;
      default =
        let
          inherit (config) description license;

          getLicense = license: lib.licenses.${license} or (lib.meta.getLicenseFromSpdxId license);
        in
        {
          platforms = config.systems;
        }
        // optionalAttrs (description != null) {
          inherit description;
        }
        // optionalAttrs (license != null) {
          license = if isList license then map getLicense license else getLicense license;
        };
    };
    finalPackages = mkOption {
      internal = true;
      readOnly = true;
      type = lazyAttrsOf (lazyAttrsOf types.package);
      default = config.genSystems' (
        { callWithArgs }:
        let
          packages = pipe cfg [
            callWithArgs
            (f: f { })
          ];
          packages' = mapAttrs (
            name: f:
            pipe f [
              callWithArgs
              (callWith (removeAttrs packages' [ name ]))
              (callWith { inherit name; })
              (f: f { })
            ]
          ) packages;
        in
        packages'
      );

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

    (mkIf (cfg != null) {
      packageOverlay =
        final: prev:
        let
          pkgDefs = getPkgDefs prev;
          getName = pkg: pkg.pname or (parseDrvName pkg.name).name;
          mockPkgs = conflake'.nameMockedPkgs prev;

          defaultPkgName = flip defaultTo config.pname (
            findFirst (x: (tryEval x).success) null [
              (getName (mockPkgs.callPackage pkgDefs.default { }))
            ]
          );
          default = genPkg final prev defaultPkgName pkgDefs.default;
        in
        pipe pkgDefs [
          (genPkgs final prev)
          (mergeAttrs (
            optionalAttrs (pkgDefs ? default && defaultPkgName != null) {
              inherit default;
              ${defaultPkgName} = default;
            }
          ))
        ];

      outputs.packages = config.finalPackages;

      devShell.inputsFrom =
        { outputs' }: optionals (outputs' ? packages.default) [ outputs'.packages.default ];
    })
  ];
}
