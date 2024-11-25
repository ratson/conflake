inputs:

let
  inherit (inputs.nixpkgs) lib;
  cases = import ./default.nix inputs;
in
if cases == [ ] then
  "Unit tests successful"
else
  throw "Unit tests failed: ${lib.generators.toPretty { } cases}"
