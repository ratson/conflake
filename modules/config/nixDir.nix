{ config, lib, ... }@args:

let
  inherit (builtins) attrValues foldl' mapAttrs pathExists readDir;

  inherit (lib) removeSuffix flip genAttrs nameValuePair mkOption pipe remove types;

  inherit (config) inputs;

  loadDir = dir:
    let
      toEntry = path: type:
        let
          fullPath = dir + /${path};
          name = removeSuffix ".nix" path;
        in
        if type == "directory" then
          nameValuePair name (loadDir fullPath)
        else if type == "regular" then
          nameValuePair name fullPath
        else null;
    in
    pipe dir [
      (x: if pathExists x then readDir x else { })
      (mapAttrs toEntry)
      attrValues
      (remove null)
      (flip foldl' { }
        (acc: { name, value }:
          acc // { ${name} = value; }))
    ];
in
{
  options = {
    nixDir = mkOption {
      type = types.path;
      default = config.src + /nix;
    };

    nixDirEntries = mkOption {
      type = types.raw;
      readOnly = true;
    };
  };

  config = {
    nixDirEntries = loadDir config.nixDir;
  };
}
