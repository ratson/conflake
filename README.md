# Conflake

A batteries included, convention-based configuration framework for Nix Flakes.

## Goals

- Minimize boilerplate needed for flakes
- Support straightforward configuration of all vanilla flake attributes
- Allow sharing common configuration using modules
- What can be done automatically, should be
- Provide good defaults, but let them be changed/disabled

## Features

- Handles generating per-system attributes
- Extensible using the module system
- Given package definitions, generates package and overlay outputs
- Automatically import attributes from nix files in a directory (default `./nix`)
- Builds formatter outputs that can format multiple file types
- Provides outputs/perSystem options for easy migration

## Documentation

See the [API docs](./API_GUIDE.md) for available options and example usage.

## Examples

### Shell

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

## Credits

This is a fork of [Flakelight](https://github.com/nix-community/flakelight) with
the following changes,

- Change `lib.mkFlake` to `lib.mkOutputs`
- Fix https://github.com/nix-community/flakelight/issues/22
