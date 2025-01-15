{ lib }:

lib.makeExtensible (self: {
  attrsets = import ./attrsets.nix { inherit lib; };

  flake = import ./flake.nix { inherit lib; };

  matchers = import ./matchers.nix;

  types = import ./types.nix { inherit lib self; };

  inherit (self.attrsets) prefixAttrs;
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
