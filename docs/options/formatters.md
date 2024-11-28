# formatters

The `formatters` option allows you to configure formatting tools that will be
used by `nix fmt`. If formatters are set, Conflake will export
`formatter.${system}` outputs which apply all the configured formatters.

By default, `nix` files are formatted with `nixpkgs-fmt` and `md`, `json`, and
`yml` files are formatted with `prettier`.

To disable default formatters, set the `conflake.builtinFormatters` option to
false.

You can set `formatters` to an attribute set, for which the keys are a file name
pattern and the value is the corresponding formatting command. `formatters` can
optionally be a function that takes packages and returns the above.

Formatting tools should be added to `devShell.packages`; this enables easier use
as described below, as well as allowing flake users to use the tools directly
when in the devShell.

Formatters can be set to a plain string like `"zig fmt"` or a full path like
`"${pkgs.zig}/bin/zig fmt"`. Formatters set as plain strings have access to all
packages in `devShell.packages`.

If building the formatter is slow due to building devShell packages, use full
paths for the formatters; the devShell packages are only included if a
formatting option is set to a plain string.

## Usage

```nix
{
  inputs.conflake.url = "github:ratson/conflake";
  outputs = { conflake, ... }:
    conflake ./. {
      devShell.packages = pkgs: [ pkgs.rustfmt pkgs.zig ];
      formatters = {
        "*.rs" = "rustfmt";
        "*.zig" = "zig fmt";
      };
    };
}
```
