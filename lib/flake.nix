{ lib, ... }:

let
  inherit (builtins) substring;
  inherit (lib) concatStrings;

  mkVersion' =
    prefix: input:
    concatStrings [
      prefix
      "+date="
      (substring 0 8 (input.lastModifiedDate or "19700101"))
      "_"
      (input.shortRev or "dirty")
    ];
in
{
  inherit mkVersion';

  /**
    Create a version string from flake input.

    # Inputs

    `input`

    : The flake input

    # Type

    ```
    mkVersion :: AttrSet -> String
    ```

    # Examples
    :::{.example}
    ## `lib.flake.mkVersion` usage example

    ```nix
    mkVersion inputs.self
    => "0.0.0+date=19700101_dirty"
    ```

    :::
  */
  mkVersion = input: mkVersion' "0.0.0" input;
}
