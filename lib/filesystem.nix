{ lib }:

let
  inherit (builtins)
    attrValues
    listToAttrs
    mapAttrs
    readDir
    ;
  inherit (lib) nameValuePair pipe remove;

  final = {
    collectPaths =
      {
        root,
        ignore ? _: false,
        # internal state
        depth ? 0,
        dir ? root,
        path ? root,
        ...
      }@args:
      pipe path [
        readDir
        (mapAttrs (
          name: type:
          let
            args' = args // {
              inherit name type;
              depth = depth + 1;
              dir = path;
              path = path + /${name};
            };
            isIgnored = ignore args';
          in
          if isIgnored then
            null
          else if type == "directory" then
            nameValuePair name (final.collectPaths args')
          else if type == "regular" then
            nameValuePair name args'.path
          else
            null
        ))
        attrValues
        (remove null)
        listToAttrs
      ];
  };
in
final
