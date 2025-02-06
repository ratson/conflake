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
  inherit (lib.types) lazyAttrsOf;
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
      type = lazyAttrsOf types.pkgs;
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
        config.genSystems (
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
    genSystems = mkOption {
      internal = true;
      readOnly = true;
      type = types.unspecified;
      default =
        f:
        genAttrs cfg (
          system:
          pipe system [
            (flip getAttr config.pkgsFor)
            config.mkSystemArgs'
            ({ pkgsCall, ... }: pkgsCall f)
          ]
        );
    };
    mkSystemArgs = mkOption {
      internal = true;
      readOnly = true;
      type = functionTo (lazyAttrsOf types.unspecified);
      default = system: {
        inherit system;
        inherit (config) defaultMeta;
        inputs' = mapAttrs (_: selectAttr system) inputs;
        outputs' = selectAttr system outputs;
      };
    };
    mkSystemArgs' = mkOption {
      internal = true;
      readOnly = true;
      type = functionTo (lazyAttrsOf types.unspecified);
      default =
        pkgs:
        let
          inherit (pkgs.stdenv.hostPlatform) system;
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
                (callWith (pkgs // moduleArgs // final))
                (f: f { })
              ];
          pkgsCall' =
            f:
            let
              f' = if isFunction f then f else import f;
              noArgs = functionArgs f' == { };
            in
            if noArgs then
              f' pkgs
            else
              pipe f' [
                (callWith (moduleArgs // final))
                (f: pkgs.callPackage f { })
              ];
          final = (config.mkSystemArgs system) // {
            inherit pkgsCall pkgsCall';
          };
        in
        final;
    };
  };
}
