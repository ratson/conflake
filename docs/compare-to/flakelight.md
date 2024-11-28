---
outline: false
---

# Compare to Flakelight

This project starts as a fork of [Flakelight](https://github.com/nix-community/flakelight) to address [the module limitation issue](https://github.com/nix-community/flakelight/issues/22), since then many changes have been made.

## Wrapped modules

Conflake creates wrapper around `nixosModules`, `homeModules` and `darwinModules` with `moduleArgs`, so that the flake consumer can import the module without errors.

Flakelight will cause error if `inputs` in module and being imported by an
external flake.

## No `_default.nix`

Conflake loads `packages/default.nix` as `packages.default`, and loading `packages.nix` is loaded as `packages`.

Flakelight loads `packages/_default.nix` as `packages.default`, and
`packages/default.nix` is reserved for `packages`.
