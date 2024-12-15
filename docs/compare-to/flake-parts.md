# Compare to Flake Parts

`Flake Parts` is a popular framework for writing Nix
Flakes and it has a strong third-party modules community.

[Documentation](https://flake.parts/)&nbsp;
[GitHub](https://github.com/hercules-ci/flake-parts)

## Differences

### Load files to attributes

`Conflake` by default loads `./nix` nix files into `outputs` attributeset.

`Flake Parts` can achieve a similar result with [ez-configs](https://github.com/ehllie/ez-configs).

### Default overlay

`Conflake` derived a `overlays.default` from `packages` by default.

`Flake Parts` requires to use the [`easyOverlay`](https://flake.parts/overlays#an-overlay-for-free-with-flake-parts) to enable that.

### Flakelight Inheritance

As `Conflake` is a fork of `Flakelight`, the [differences](https://discourse.nixos.org/t/flakelight-a-new-modular-flake-framework/32395/3) mentioned by the author of `Flakelight` apply here too.
