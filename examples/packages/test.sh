#!/usr/bin/env bash
set -ex

nix_build() {
    nix build --no-link --override-input conflake ../.. --reference-lock-file flake.lock "$@"
}

nix_run() {
    nix run --override-input conflake ../.. --reference-lock-file flake.lock "$@"
}

nix_run
nix_run .#greet
nix_run .#hi
nix_run .#haloha
nix_run .#hei

nix_build .#devShells.x86_64-linux.default

nix_build .#legacyPackages.x86_64-linux.emacsPackages.azul
nix_build .#legacyPackages.x86_64-linux.emacsPackages.greet
nix_build .#legacyPackages.x86_64-linux.emacsPackages.hi
nix_build .#legacyPackages.x86_64-linux.emacsPackages.hei
