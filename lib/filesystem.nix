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
        dir,
        ignore ? _: false,
        maxDepth ? null,
        depth ? 1,
        ...
      }@args:
      pipe dir [
        readDir
        (mapAttrs (
          name: type:
          let
            path = dir + /${name};
            args' = args // {
              inherit name type;
              depth = depth + 1;
              dir = path;
            };
            isIgnored = (type == "directory" && maxDepth != null && depth >= maxDepth) || ignore args';
          in
          if isIgnored then
            null
          else if type == "directory" then
            nameValuePair name (final.collectPaths args')
          else if type == "regular" then
            nameValuePair name path
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
