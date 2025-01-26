{ lib, ... }:

{
  singleton = {
    expr = lib.singleton 1;
    expected = [ 1 ];
  };
}
