# This is a fake pkgs set to enable efficiently extracting a derivation's name
real:

let
  inherit (builtins)
    baseNameOf
    intersectAttrs
    mapAttrs
    ;
  inherit (real) lib;
  inherit (lib)
    fix
    filterAttrs
    functionArgs
    isFunction
    ;

  callPackageWith =
    autoArgs: fn: args:
    let
      f = if isFunction fn then fn else import fn;
      fargs = functionArgs f;
      mock = mapAttrs (_: _: throw "") (filterAttrs (_: v: !v) fargs);
    in
    assert fargs != { };
    f (mock // intersectAttrs fargs autoArgs // args);

  mockStdenv = mapAttrs (_: _: throw "") real.stdenv // {
    mkDerivation = args: if isFunction args then fix args else args;
  };
in
fix (self: {
  lib = lib // {
    inherit callPackageWith;
  };

  callPackage = callPackageWith self;

  stdenv = mockStdenv;
  stdenvNoCC = mockStdenv;
  stdenv_32bit = mockStdenv;
  stdenvNoLibs = mockStdenv;
  libcxxStdenv = mockStdenv;
  gccStdenv = mockStdenv;
  gccStdenvNoLibs = mockStdenv;
  gccMultiStdenv = mockStdenv;
  clangStdenv = mockStdenv;
  clangStdenvNoLibs = mockStdenv;
  clangMultiStdenv = mockStdenv;
  ccacheStdenv = mockStdenv;

  runCommandWith = args: _: args;
  runCommand = name: _: _: { inherit name; };
  runCommandLocal = name: _: _: { inherit name; };
  runCommandCC = name: _: _: { inherit name; };
  writeTextFile = args: args;
  writeText = name: _: { inherit name; };
  writeTextDir = path: _: { name = baseNameOf path; };
  writeScript = name: _: { inherit name; };
  writeScriptBin = name: _: { inherit name; };
  writeShellScript = name: _: { inherit name; };
  writeShellScriptBin = name: _: { inherit name; };
  writeShellApplication = args: args;
  writeCBin = pname: _: { inherit pname; };
  concatTextFile = args: args;
  concatText = name: _: { inherit name; };
  concatScript = name: _: { inherit name; };
  symlinkJoin = args: args;
  linkFarm = name: _: { inherit name; };
  linkFarmFromDrvs = name: _: { inherit name; };
})
