{ config, lib, genPkgs, ... }:

let
  inherit (lib) mapAttrs mkIf mkMerge mkOption types;

  devShellType2 = types.submodule {
    freeformType = types.raw;

    options = {
      inputsFrom = mkOption {
        type = types.listOf types.raw;
        default = [ ];
      };

      packages = mkOption {
        type = types.listOf types.raw;
        default = [ ];
      };

      shellHook = mkOption {
        type = types.lines;
        default = "";
      };
    };

    config = {
      _module.args = config._module.args;
    };
  };

  devShellType = types.raw;
in
{
  options = {
    devShell = mkOption {
      type = types.nullOr devShellType;
      default = null;
    };

    devShells = mkOption {
      type = types.lazyAttrsOf devShellType;
      default = { };
    };
  };

  config = mkMerge [
    (mkIf (config.nixDirEntries ? devShells) {
      devShells = config.nixDirEntries.devShells;
    })

    (mkIf (config.devShell != null) {
      devShells.default = config.devShell;
    })

    (mkIf (config.devShells != { }) {
      outputs = {
        devShells = genPkgs
          ({ pkgs, callPackage, ... }: mapAttrs
            (_: cfg: callPackage cfg { })
            config.devShells);
      };
    })
  ];
}

