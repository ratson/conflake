{ hello, ... }:

hello.overrideAttrs (_: {
  pname = "broken-here";

  preUnpack = "exit 1";
})
