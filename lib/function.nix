{ lib }:

let
  inherit (builtins)
    hasAttr
    intersectAttrs
    mapAttrs
    ;
  inherit (lib)
    functionArgs
    isFunction
    setFunctionArgs
    ;
in
{
  callWith =
    autoArgs: fn:
    let
      f = if isFunction fn then fn else import fn;
      fargs = functionArgs f;

      fallbackArgs = intersectAttrs fargs autoArgs;
      fargs' = mapAttrs (k: v: v || hasAttr k fallbackArgs) fargs;

      noArgs = fargs == { };
      fallbackArgs' = if noArgs then autoArgs else fallbackArgs;

      f' = args: f (fallbackArgs' // args);
    in
    setFunctionArgs f' fargs';
}
