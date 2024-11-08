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

See the [Quick-start Guide](https://ratson.github.io/conflake/guide/getting-started.html) and [API docs](https://ratson.github.io/conflake/reference/api.html) for available options and example usage.

## Credits

This is a fork of [Flakelight](https://github.com/nix-community/flakelight) with
the following changes,

- Change `lib.mkFlake` to `lib.mkOutputs`
- Fix <https://github.com/nix-community/flakelight/issues/22>
- Load `packages/default.nix` as `packages.default` instead of `packages`
