{ lib }:

let
  inherit (builtins) head match;
in
{
  getUsername = s: head (match "([^@]*)(@.*)?" s);
}
