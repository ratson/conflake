# bundlers

The `bundler` and `bundlers` options allow you to set `bundlers.${system}`
outputs.

Each bundler value can be either a bundler function or a function that takes the
package set and returns a bundler function.

`bundlers` is an attribute set of bundler values or a function that takes
packages and returns an attribute set of bundler values.

`bundler` sets `bundlers.default`.

## Usage

For example, a bundler that returns the passed package:

```nix
{
  inputs.conflake.url = "github:ratson/conflake";
  outputs = { conflake, ... }:
    conflake ./. {
      bundler = x: x;
    };
}
```

As another example, a bundler that always returns `hello`:

```nix
{
  inputs.conflake.url = "github:ratson/conflake";
  outputs = { conflake, ... }:
    conflake ./. {
      bundlers = { hello, ... }: {
        hello = x: hello;
      };
    };
}
```

To write the above using autoloads, can use the following:

```nix
# nix/bundlers/hello.nix
{ hello, ... }: x: hello;
```
