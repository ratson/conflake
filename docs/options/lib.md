# lib

The `lib` option allows you to configure the flake's `lib` output.

## Usage

For example:

```nix
{
  inputs.conflake.url = "github:ratson/conflake";
  outputs = { conflake, ... }:
    conflake ./. {
      lib = {
        addFive = x: x + 5;
        addFour = x: x + 4;
      };
    };
}
```
