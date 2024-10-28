{ config, lib, ... }:

let
  inherit (builtins) attrValues foldl' mapAttrs pathExists readDir;

  inherit (lib) removeSuffix flip genAttrs nameValuePair mkOption pipe remove types;

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

  pkgsBySystem = genAttrs config.systems (system: import config.inputs.nixpkgs {
    inherit system;
  });

  packages = mapAttrs
    (system: pkgs:
      mapAttrs (_: v: pkgs.callPackage v { }) config.nixDirEntries.packages or { })
    pkgsBySystem;
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

    outputs = {
      inherit packages;
    };
  };
}
