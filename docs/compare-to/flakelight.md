# Compare to Flakelight

This project began as a fork of `Flakelight` to address [module limitation issue](https://github.com/nix-community/flakelight/issues/22).

Many changes, features, and bug fixes have been made since then.
While most APIs are intact, it’s not fully compatible.

[Documentation](https://github.com/nix-community/flakelight/blob/master/API_GUIDE.md)&nbsp;
[GitHub](https://github.com/nix-community/flakelight)

## Differences

### Wrapped modules

`Conflake` creates wrapper around `nixosModules`, `homeModules` and `darwinModules` with `moduleArgs`, so that the flake consumer can import the module without errors.

`Flakelight` will cause error if `inputs` in module and being imported by an
external flake.

### No `_default.nix`

`Conflake` loads `packages/default.nix` as `packages.default`, and loading `packages.nix` is loaded as `packages`.

`Flakelight` loads `packages/_default.nix` as `packages.default`, and
`packages/default.nix` is reserved for `packages`.
