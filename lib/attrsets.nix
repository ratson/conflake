{ lib }:

let
  inherit (builtins) mapAttrs;
  inherit (lib)
    fix
    flip
    mapAttrs'
    nameValuePair
    pipe
    versionOlder
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

  /**
    Select attrset with higher version.

    # Inputs

    `a.version`

    : First attrset version

    `b.version`

    : Second attrset version

    # Type

    ```
    sselectHigherVersion :: AttrSet -> AttrSet -> AttrSet
    ```

    # Examples
    :::{.example}
    ## `lib.attrsets.selectHigherVersion` usage example

    ```nix
    selectHigherVersion { version = "1.0"; } { version = "2.0"; }
    => { version = "2.0"; }
    ```

    :::
  */
  selectHigherVersion = a: b: if versionOlder a.version b.version then b else a;
})
