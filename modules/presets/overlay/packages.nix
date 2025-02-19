{
  config,
  lib,
  conflake,
  moduleArgs,
  ...
}:

let
  inherit (builtins)
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
    mkEnableOption
    mkIf
    mkOption
    optionalAttrs
    pipe
    types
    ;
  inherit (conflake.internal) nameMockedPkgs;
  inherit (conflake.types) overlay;

  cfg = config.presets.overlay.packages;

  genPkg =
    final: prev: name: pkg:
    let
      inherit (prev.stdenv.hostPlatform) system;
      args = functionArgs pkg;
      noArgs = args == { };
      pkg' = if noArgs then { pkgs }: pkg pkgs else pkg;
      dependsOnSelf = hasAttr name args;
      dependsOnPkgs = noArgs || (args ? pkgs);
      selfOverride = {
        ${name} = prev.${name} or (throw "${name} depends on ${name}, but no existing ${name}.");
      };
      overrides =
        filterAttrs (k: _: hasAttr k args) (moduleArgs // (config.mkSystemArgs system))
        // optionalAttrs dependsOnSelf selfOverride
        // optionalAttrs dependsOnPkgs { pkgs = final.pkgs // selfOverride; };
    in
    final.callPackage pkg' overrides;
  genPkgs =
    final: prev: pkgs:
    mapAttrs (name: genPkg final prev name) pkgs;

  getPkgDefs = flip pipe [
    config.mkSystemArgs'
    ({ pkgsCall, ... }: pkgsCall config.packages)
  ];
in
{
  options = {
    presets.overlay.packages = {
      enable = mkEnableOption "packages overlay" // {
        default = config.presets.overlay.enable;
      };
      blacklist = mkOption {
        type = types.listOf types.str;
        default = [ ];
      };
    };
    packageOverlay = mkOption {
      internal = true;
      type = types.uniq overlay;
      default = _: _: { };
    };
  };

  config = mkIf (cfg.enable && config.packages != null) {
    packageOverlay =
      final: prev:
      let
        pkgDefs = getPkgDefs prev;
        getName = pkg: pkg.pname or (parseDrvName pkg.name).name;
        mockPkgs = nameMockedPkgs prev;

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

    nixpkgs.overlays = [ config.packageOverlay ];

    overlay =
      final:
      flip pipe [
        (config.packageOverlay (final.appendOverlays config.nixpkgs.overlays))
        (flip removeAttrs ([ "default" ] ++ cfg.blacklist))
      ];
  };
}
