{ lib, ... }:

let
  inherit (builtins)
    fromJSON
    head
    isString
    mapAttrs
    readFile
    substring
    tail
    ;
  inherit (lib) concatStrings fix pipe;

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

  lock2inputs =
    src:
    let
      json = pipe src [
        readFile
        fromJSON
      ];
      inherit (json) nodes root;

      getInputName =
        base: ref:
        let
          next = getInputName root nodes.${base}.inputs.${head ref};
        in
        if isString ref then
          ref
        else if ref == [ ] then
          base
        else
          getInputName next (tail ref);

      getInput = ref: resolved.${getInputName root ref};

      fetchNode = node: fetchTree (node.info or { } // removeAttrs node.locked [ "dir" ]);

      resolveFlakeNode =
        node:
        fix (
          self:
          let
            sourceInfo = fetchNode node;
            outPath = sourceInfo + (if node.locked ? dir then "/${node.locked.dir}" else "");
            inputs = (mapAttrs (_: getInput) (node.inputs or { })) // {
              inherit self;
            };
            outputs = (import (outPath + "/flake.nix")).outputs inputs;
          in
          outputs
          // sourceInfo
          // {
            _type = "flake";
            inherit
              inputs
              outPath
              outputs
              sourceInfo
              ;
          }
        );

      resolveNode = node: if node.flake or true then resolveFlakeNode node else fetchNode node;

      resolved = mapAttrs (_: resolveNode) nodes;
    in
    mapAttrs (_: getInput) nodes.${root}.inputs;

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
