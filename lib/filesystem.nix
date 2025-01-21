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
        ...
      }@args:
      pipe dir [
        readDir
        (
          x:
          mapAttrs (
            name: type:
            let
              path = dir + /${name};
              args' = args // {
                inherit name type;
                dir = path;
                entries = x;
              };
            in
            if ignore args' then
              null
            else if type == "directory" then
              nameValuePair name (final.collectPaths args')
            else if type == "regular" then
              nameValuePair name path
            else
              null
          ) x
        )
        attrValues
        (remove null)
        listToAttrs
      ];
  };
in
final
