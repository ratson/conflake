{ lib }:

lib.makeExtensible (self: {
  attrsets = import ./attrsets.nix { inherit lib; };

  flake = import ./flake.nix { inherit lib; };

  inherit (self.attrsets) prefixAttrs;
  inherit (self.flake) mkVersion mkVersion';
})
