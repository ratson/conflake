{ lib }:

let
  inherit (builtins)
    hasAttr
    intersectAttrs
    mapAttrs
    ;
  inherit (lib)
    fix
    functionArgs
    isFunction
    setFunctionArgs
    ;
in
fix (self: {
  callMustWith = self.callWith' { merge = true; };

  callWith = self.callWith' { };

  callWith' =
    {
      merge ? false,
    }:
    autoArgs: fn:
    let
      f = if isFunction fn then fn else import fn;
      fargs = functionArgs f;

      fallbackArgs = intersectAttrs fargs autoArgs;
      fargs' = mapAttrs (k: v: v || hasAttr k fallbackArgs) fargs;

      noArgs = fargs == { };
      fallbackArgs' = if merge && noArgs then autoArgs else fallbackArgs;

      f' = args: f (fallbackArgs' // args);
    in
    if noArgs then f' else setFunctionArgs f' fargs';
})
