# functor

The `functor` option allows you to make your flake callable.

If it is set to a function, that function will be set as the `__functor`
attribute of your flake outputs.

Conflake uses it so that calling your `conflake` input calls
`conflake.lib.mkOutputs`.

## Usage

As an example:

```nix
{
  inputs.conflake.url = "github:ratson/conflake";
  outputs = { conflake, ... }:
    conflake ./. {
      outputs.testvalue = 5;
      functor = self: x: x + self.testvalue;
    }
}
```

With the above flake, another flake that has imports it with the name `addFive`
would be able to call `addFive 4` to get 9.
