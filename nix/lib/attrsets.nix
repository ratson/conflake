{ lib, ... }:

let
  inherit (lib) mapAttrs' nameValuePair;
in
{
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
  prefixAttrs = prefix: mapAttrs' (k: nameValuePair "${prefix}${k}");
}
