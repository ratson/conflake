{
  config,
  lib,
  inputs,
  conflake,
  moduleArgs,
  outputs,
  ...
}:

let
  inherit (builtins) getAttr mapAttrs;
  inherit (lib)
    flip
    genAttrs
    mkOption
    pipe
    types
    ;
  inherit (lib.types) coercedTo lazyAttrsOf;
  inherit (conflake) callWith selectAttr;
  inherit (conflake.types) functionTo;

  cfg = config.systems;
in
{
  options = {
    systems = mkOption {
      type = conflake.types.systems;
      default = inputs.systems or lib.systems.flakeExposed;
    };

    pkgsFor = mkOption {
      internal = true;
      readOnly = true;
      type = coercedTo (functionTo types.pkgs) (v: genAttrs cfg (flip getAttr v)) (
        lazyAttrsOf types.pkgs
      );
      default =
        if config.nixpkgs.config == { } && config.nixpkgs.overlays == [ ] then
          inputs.nixpkgs.legacyPackages
        else
          genAttrs cfg (
            system:
            import inputs.nixpkgs {
              inherit system;
              inherit (config.nixpkgs) config overlays;
            }
          );
    };
    callSystemsWithAttrs = mkOption {
      internal = true;
      readOnly = true;
      type = types.unspecified;
      default =
        fn:
        config.genSystems' (
          { callWithArgs }:
          pipe fn [
            callWithArgs
            (f: f { })
            (mapAttrs (
              name: f:
              pipe f [
                callWithArgs
                (callWith { inherit name; })
                (f: f { })
              ]
            ))
          ]
        );
    };
    genSystems' = mkOption {
      internal = true;
      readOnly = true;
      type = types.unspecified;
      default =
        f:
        mapAttrs (
          _:
          { callWithArgs, ... }:
          pipe f [
            callWithArgs
            (f: f { })
          ]
        ) config.systemArgsFor';
    };
    mkSystemArgs' = mkOption {
      internal = true;
      readOnly = true;
      type = types.unspecified;
      default = pkgs: config.mkSystemArgs pkgs.stdenv.hostPlatform.system;
    };
    mkSystemArgs = mkOption {
      internal = true;
      readOnly = true;
      type = types.unspecified;
      default = system: {
        inherit inputs outputs system;
        inherit (config) defaultMeta;
        inputs' = mapAttrs (_: selectAttr system) inputs;
        outputs' = selectAttr system outputs;
      };
    };
    systemArgsFor = mkOption {
      internal = true;
      readOnly = true;
      type = lazyAttrsOf (lazyAttrsOf types.unspecified);
      default = genAttrs cfg (system: {
        inherit system;
        inherit (config) defaultMeta;
        inputs' = mapAttrs (_: selectAttr system) inputs;
        outputs' = selectAttr system outputs;
      });
    };
    systemArgsFor' = mkOption {
      internal = true;
      readOnly = true;
      type = lazyAttrsOf (lazyAttrsOf types.unspecified);
      default = mapAttrs (
        system: v:
        let
          v' = v // {
            inherit callWithArgs pkgs;
          };
          pkgs = config.pkgsFor.${system};
          callWithArgs = flip pipe [
            (callWith pkgs)
            (callWith moduleArgs)
            (callWith v')
          ];
        in
        v'
      ) config.systemArgsFor;
    };
  };
}
