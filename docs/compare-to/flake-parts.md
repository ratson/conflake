# Compare to Flake Parts

[Flake Parts](https://flake.parts/) is a popular framework for writing Nix
Flakes and it has a strong third-party modules community.

## File-system based attributes

Conflake by default loads `./nix` nix files into `outputs` attributeset.

Flake Parts can achieve a similar result with [ez-configs](https://github.com/ehllie/ez-configs).

## Default overlay

Conflake derived a `overlays.default` from `packages` by default.

Flake Parts requires to use the [`easyOverlay`](https://flake.parts/overlays#an-overlay-for-free-with-flake-parts) to enable that.

## Compare to Flakelight

The author of Flakelight has stated [some of the differences](https://discourse.nixos.org/t/flakelight-a-new-modular-flake-framework/32395/3),
it applies to Conflake too, since Conflake is a fork of Flakelight.
