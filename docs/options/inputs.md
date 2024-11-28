# inputs

The `inputs` option is an attrset of the flake inputs used by conflake
modules. These inputs get passed as the `inputs` module argument, and are used
for `inputs` and `inputs'` in the package set.

### Usage

```nix
{
  inputs = {
    conflake.url = "github:ratson/conflake";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };
  outputs = { conflake, ... }@inputs:
    conflake ./. {
      inherit inputs;
    };
}
```
