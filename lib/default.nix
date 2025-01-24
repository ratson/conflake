{ lib }:

lib.makeExtensible (self: {
  attrsets = import ./attrsets.nix { inherit lib; };

  filesystem = import ./filesystem.nix { inherit lib; };

  flake = import ./flake.nix { inherit lib; };

  matchers = import ./matchers.nix { inherit lib; };

  types = import ./types.nix {
    inherit lib;
    lib' = self;
  };

  inherit (self.attrsets) selectAttr prefixAttrs;
  inherit (self.filesystem) collectPaths;
  inherit (self.flake) mkVersion mkVersion';

  mkCheck =
    name: pkgs: src: cmd:
    pkgs.runCommandLocal "check-${name}" { } ''
      pushd "${src}"
      ${cmd}
      popd
      touch $out
    '';
})
