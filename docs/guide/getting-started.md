# Getting Started

If your project does not have a flake yet:

```nix
nix flake init -t github:ratson/conflake
```

## Add to project

Otherwise, edit `flake.nix` to the following,

```nix
{
  inputs.conflake.url = "github:ratson/conflake";
  outputs = { conflake, ... }:
    conflake ./. {
      inherit inputs;

      outputs = {
        # Put your existing `outputs` here
      };
    };
}
```

Then migrate your `outputs` to conflake [`options`](../options).

## Shell

The following is an example flake.nix for a devshell, using the passed in
nixpkgs. It outputs `devShell.${system}.default` attributes for each configured
system. `systems` can be set to change configured systems from the default.

```nix
{
  inputs.conflake.url = "github:ratson/conflake";
  outputs = { conflake, ... }:
    conflake ./. {
      devShell.packages = pkgs: [ pkgs.hello pkgs.coreutils ];
    };
}
```

With this flake, calling `nix develop` will make `hello` and `coreutils`
available.

To use a different nixpkgs, you can instead use:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    conflake.url = "github:ratson/conflake";
  };
  outputs = { conflake, ... }@inputs:
    conflake ./. {
      inherit inputs;
      devShell.packages = pkgs: [ pkgs.hello pkgs.coreutils ];
    };
}
```

## mkOutputs

The outputs of a flake using Conflake are created using the `mkOutputs` function.
When called directly, Conflake invokes `mkOutputs`, as follows:

```nix
{
  inputs.conflake.url = "github:ratson/conflake";
  outputs = { conflake, ... }:
    conflake ./. {
      # Your flake configuration here
    };
}
```

To call `mkOutputs` explicitly, you can do:

```nix
{
  inputs.conflake.url = "github:ratson/conflake";
  outputs = { conflake, ... }:
    conflake.lib.mkOutputs ./. {
      # Your flake configuration here
    };
}
```

`mkOutputs` takes two parameters: the path to the flake's source and a Conflake
module.

If you need access to module args, you can write it as bellow:

```nix
{
  inputs.conflake.url = "github:ratson/conflake";
  outputs = { conflake, ... }:
    conflake ./. ({ lib, config, ... }: {
      # Your flake configuration here
    });
}
```

## Module arguments

The following module arguments are available:

- `src`: The flake's source directory
- `lib`: nixpkgs lib attribute
- `config`: configured option values
- `options`: available options
- `conflake`: conflake lib attribute
- `inputs`: value of inputs option
- `outputs`: resulting output (i.e. final flake attributes)
- `pkgsFor`: attrset mapping systems to the pkgs set for that system
- `moduleArgs`: All of the available arguments (passed to auto-loaded files)

## Additional pkgs values

Functions that take the package set as an argument, such as package definitions
or `perSystem` values, have several additional values available in the package
set.

The `src`, `conflake`, `inputs`, `outputs`, and `moduleArgs` attributes are
the same as the above module arguments.

`inputs'` and `outputs'` are transformed versions of `inputs` and `outputs` with
system preselected. I.e., `inputs.emacs-overlay.packages.x86_64-linux.default`
can be accessed as `inputs'.emacs-overlay.packages.default`.

`defaultMeta` is a derivation meta attribute set generated from options. Modules
setting `packages.default` should use this to allow meta attributes to be
configured.
