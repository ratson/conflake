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
  inherit (builtins) mapAttrs;
  inherit (lib)
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
      type = functionTo (lazyAttrsOf (lazyAttrsOf types.unspecified));
      default =
        fn:
        config.genSystems (
          { pkgsCall, ... }: mapAttrs (name: f: pkgsCall (callWith { inherit name; } f)) (pkgsCall fn)
        );
    };
    genSystems = mkOption {
      internal = true;
      readOnly = true;
      type = functionTo (lazyAttrsOf types.unspecified);
      default = f: genAttrs cfg (system: f (config.mkSystemArgs' config.pkgsFor.${system}));
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
            inherit pkgs pkgsCall pkgsCall';
          };
        in
        final;
    };
  };
}
