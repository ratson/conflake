{ config, lib, ... }:

let
  loadDir = dir:
    let
      toEntry = path: type:
        let
          fullPath = dir + /${path};
          name = lib.removeSuffix ".nix" path;
        in
        if lib.hasPrefix "_" path then null
        else if type == "directory" then
          lib.nameValuePair name (loadDir fullPath)
        else if type == "regular" && lib.hasSuffix ".nix" path then
          lib.nameValuePair name fullPath
        else null;
    in
    lib.pipe dir [
      (x: lib.optionalAttrs (builtins.pathExists x) (builtins.readDir x))
      (builtins.mapAttrs toEntry)
      builtins.attrValues
      (lib.remove null)
      (lib.flip builtins.foldl' { }
        (acc: { name, value }:
          acc // { ${name} = value; }))
    ];
in
{
  options = {
    nixDir = lib.mkOption {
      type = lib.types.path;
      default = config.src + /nix;
    };

    nixDirEntries = lib.mkOption {
      type = lib.types.raw;
      readOnly = true;
    };
  };

  config = {
    nixDirEntries = loadDir config.nixDir;
  };
}
