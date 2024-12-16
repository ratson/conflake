{
  config,
  lib,
  src,
  ...
}:

let
  inherit (builtins)
    fromJSON
    head
    isString
    mapAttrs
    readFile
    tail
    ;
  inherit (lib)
    fix
    mkEnableOption
    mkIf
    mkOverride
    pathIsRegularFile
    pipe
    ;

  flakeLock = src + /flake.lock;

  lock2inputs =
    { nodes, root, ... }:
    let
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
in
{
  options.presets.inputs.enable = mkEnableOption "auto inputs" // {
    default = config.presets.enable;
  };

  config = mkIf (config.inputs == null && pathIsRegularFile flakeLock) {
    finalInputs = pipe flakeLock [
      readFile
      fromJSON
      lock2inputs
      (mapAttrs (_: mkOverride 950))
    ];
  };
}
