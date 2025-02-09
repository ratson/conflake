{ hello, ... }:

hello.overrideAttrs (_: {
  pname = "broken";

  preUnpack = "exit 1";
})
