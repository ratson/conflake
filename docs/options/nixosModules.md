# nixosModules

The `nixosModules` options allow you to configure the corresponding outputs.

The `nixosModule` options set the `nixosModules.default`.

## Usage

For example:

```nix
{
  inputs.conflake.url = "github:ratson/conflake";
  outputs = { conflake, ... }:
    conflake ./. ({ lib, ... }: {
      nixosModule = { system, lib, pkgs, ... }: {
        # nixos module configuration
      };
    });
}
```

These can be paths, which is preferred as it results in better debug output:

```nix
{
  inputs.conflake.url = "github:ratson/conflake";
  outputs = { conflake, ... }:
    conflake ./. ({ lib, ... }: {
      nixosModule = ./module.nix;
    });
}
```
