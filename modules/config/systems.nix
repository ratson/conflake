{
  config,
  lib,
  inputs,
  conflake,
  moduleArgs,
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
  inherit (lib.types)
    coercedTo
    functionTo
    lazyAttrsOf
    listOf
    nonEmptyStr
    package
    uniq
    ;
  inherit (conflake) callWith selectAttr;

  cfg = config.systems;

  genSystems = f: genAttrs cfg (system: f config.pkgsFor.${system});

  mkSystemArgs = system: {
    inherit system;
    inputs' = mapAttrs (_: selectAttr system) inputs;
    outputs' = selectAttr system config.outputs;
  };

  mkSystemArgs' = pkgs: mkSystemArgs pkgs.stdenv.hostPlatform.system;
in
{
  options = {
    systems = mkOption {
      type = coercedTo package import (uniq (listOf nonEmptyStr));
      default = inputs.systems or lib.systems.flakeExposed;
    };

    pkgsFor = mkOption {
      internal = true;
      readOnly = true;
      type = coercedTo (functionTo types.pkgs) (v: genAttrs cfg (flip getAttr v)) (
        lazyAttrsOf types.pkgs
      );
      default = genAttrs cfg (
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
    genSystems = mkOption {
      internal = true;
      readOnly = true;
      type = types.unspecified;
      default = genSystems;
    };
    genSystems' = mkOption {
      internal = true;
      readOnly = true;
      type = types.unspecified;
      default =
        f:
        genAttrs cfg (
          system:
          let
            pkgs = config.pkgsFor.${system};
            callWithArgs = flip pipe [
              (callWith pkgs)
              (callWith moduleArgs)
              (callWith (mkSystemArgs system))
              (callWith {
                inherit pkgs;
                inherit (config) defaultMeta;
              })
            ];
          in
          pipe f [
            callWithArgs
            (callWith { inherit callWithArgs; })
            (f: f { })
          ]
        );
    };
    mkSystemArgs' = mkOption {
      internal = true;
      readOnly = true;
      type = types.unspecified;
      default = mkSystemArgs';
    };
    mkSystemArgs = mkOption {
      internal = true;
      readOnly = true;
      type = types.unspecified;
      default = mkSystemArgs;
    };
  };
}
