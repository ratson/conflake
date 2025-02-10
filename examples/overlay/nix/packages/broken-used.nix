{ pkgs, broken, ... }:

pkgs.writeShellScriptBin "broken-deep" ''
  exec ${broken}/bin/hello "$@"
''
