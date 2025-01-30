{ lib }:

{
  isAttrTest = x: x ? "expr" && x ? "expected";
}
