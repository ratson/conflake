# Getting Started

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
