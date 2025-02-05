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
    functionArgs
    genAttrs
    isFunction
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
          { pkgsCall }:
          pipe fn [
            pkgsCall
            (mapAttrs (
              name: f:
              pipe f [
                (callWith { inherit name; })
                pkgsCall
              ]
            ))
          ]
        );
    };
    genSystems' = mkOption {
      internal = true;
      readOnly = true;
      type = types.unspecified;
      default = f: mapAttrs (_: { pkgsCall, ... }: pkgsCall f) config.systemArgsFor';
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
          pkgs = config.pkgsFor.${system};
          pkgsCall =
            f:
            let
              f' = if isFunction f then f else import f;
              noArgs = functionArgs f' == { };
            in
            if noArgs then
              f' pkgs
            else
              pipe f' [
                (callWith pkgs)
                (callWith moduleArgs)
                (callWith v')
                (f: f { })
              ];
          v' = v // {
            inherit pkgs pkgsCall;
          };
        in
        v'
      ) config.systemArgsFor;
    };
  };
}
