{ lib }:

let
  inherit (builtins) head length;
  inherit (lib)
    last
    pipe
    sublist
    throwIf
    ;
in
{
  isAttrTest = x: x ? "expr" && x ? "expected";

  mkTestFromList =
    v:
    throwIf (length v < 2) "list should have at least 2 elements" {
      expr = pipe (head v) (sublist 1 ((length v) - 2) v);
      expected = last v;
    };
}
