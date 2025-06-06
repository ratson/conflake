{ lib }:

lib.makeExtensible (self: {
  attrsets = import ./attrsets.nix { inherit lib; };

  debug = import ./debug.nix { inherit lib; };

  filesystem = import ./filesystem.nix { inherit lib; };

  flake = import ./flake.nix { inherit lib; };

  function = import ./function.nix { inherit lib; };

  internal = import ./internal/default.nix { inherit lib; };

  loaders = import ./loaders.nix { inherit lib; };

  matchers = import ./matchers.nix { inherit lib; };

  strings = import ./strings.nix { inherit lib; };

  types = import ./types.nix {
    inherit lib;
    lib' = self;
  };

  inherit (self.attrsets)
    prefixAttrs
    prefixAttrsCond
    selectAttr
    selectHigherVersion
    ;
  inherit (self.filesystem) collectPaths;
  inherit (self.flake) mkVersion mkVersion';
  inherit (self.function) callMustWith callWith;
})
