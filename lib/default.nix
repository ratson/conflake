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

  types = import ./types.nix {
    inherit lib;
    lib' = self;
  };

  inherit (self.attrsets) selectAttr prefixAttrs prefixAttrsCond;
  inherit (self.filesystem) collectPaths;
  inherit (self.flake) mkVersion mkVersion';
  inherit (self.function) callMustWith callWith;

  mkCheck =
    {
      name,
      src,
      runCommandLocal,
      ...
    }:
    cmd:
    runCommandLocal "check-${name}" { } ''
      pushd "${src}"
      if  [ -x "${cmd}" ]; then
        ${cmd}
      fi
      popd
      touch $out
    '';
})
