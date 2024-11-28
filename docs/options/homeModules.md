# homeModules

The `homeModules` options allow you to configure the corresponding outputs.

The `homeModule` options set the `homeModules.default`.

## Usage

For example:

```nix
{
  inputs.conflake.url = "github:ratson/conflake";
  outputs = { conflake, ... }:
    conflake ./. ({ lib, ... }: {
      homeModule = { system, lib, pkgs, ... }: {
        # module configuration
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
      homeModules = {
        default = ./home.nix;
        emacs = ./emacs.nix;
      }
    });
}
```
