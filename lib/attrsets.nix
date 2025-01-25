{ lib }:

let
  inherit (builtins) mapAttrs;
  inherit (lib)
    fix
    flip
    mapAttrs'
    nameValuePair
    pipe
    ;
in
fix (self: {
  /**
    Add prefix to each name in an attribute set.

    # Inputs

    `prefix`

    : Prefix to prepend

    # Type

    ```
    prefixAttrs :: String -> AttrSet -> AttrSet
    ```

    # Examples
    :::{.example}
    ## `lib.attrsets.prefixAttrs` usage example

    ```nix
    prefixAttrs "test-" { case = 1; }
    => { test-case = 1; }
    ```

    :::
  */
  prefixAttrs = self.prefixAttrsCond (_: _: true);

  prefixAttrsCond =
    cond: prefix:
    mapAttrs' (
      k: v:
      pipe k [
        (_: (if cond k v then "${prefix}${k}" else k))
        (flip nameValuePair v)
      ]
    );

  selectAttr = attr: mapAttrs (_: v: v.${attr} or { });
})
