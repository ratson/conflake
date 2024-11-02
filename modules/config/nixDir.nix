{ config, options, src, lib, conflake, ... }:

let
  inherit (builtins) attrNames pathExists;
  inherit (lib) findFirst genAttrs mkIf mkOption subtractLists;
  inherit (lib.types) attrsOf listOf str;
  inherit (conflake) importDir;
  inherit (conflake.types) path;

  inherit (config) nixDir;

  importName = name:
    if pathExists (nixDir + "/${name}.nix")
    then { success = true; value = import (nixDir + "/${name}.nix"); }
    else if pathExists (nixDir + "/${name}/default.nix")
    then { success = true; value = import (nixDir + "/${name}"); }
    else if pathExists (nixDir + "/${name}")
    then { success = true; value = importDir (nixDir + "/${name}"); }
    else { success = false; };

  importNames = names:
    findFirst (x: x.success) { success = false; } (map importName names);
in
{
  options = {
    nixDir = mkOption {
      type = path;
      default = src + /nix;
    };

    nixDirAliases = mkOption {
      type = attrsOf (listOf str);
      default = { };
    };
  };

  config = genAttrs (subtractLists [ "_module" "nixDir" ] (attrNames options))
    (name:
      let
        internal = options.${name}.internal or false;
        val = importNames
          (if name == "nixDirAliases" then [ name ] else
          ([ name ] ++ config.nixDirAliases.${name} or [ ]));
        cond = !internal && val.success;
      in
      mkIf cond (if cond then val.value else { }));
}
