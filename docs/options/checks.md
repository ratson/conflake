# checks

The `checks` option allows you to add checks for `checks.${system}` attributes.

It can be set to an attribute set of checks, which can be functions,
derivations, or strings.

If a check is a derivation, it will be used as is.

If a check is a string, it will be included in a bash script that runs it in a
copy of the source directory, and succeeds if the no command in the string
errored.

If a check is a function, it will be passed packages, and should return one of
the above.

## Usage

For example:

```nix
{
  inputs.conflake.url = "github:ratson/conflake";
  outputs = { conflake, ... }:
    conflake ./. {
      checks = {
        # Check that succeeds if the source contains the string "hi"
        hi = { rg, ... }: "${rg}/bin/rg hi";
        # Check that emacs builds
        emacs = pkgs: pkgs.emacs;
      };
    };
}
```
