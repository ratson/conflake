#!/usr/bin/env bash
set -ex

nix run
nix run .#greet
nix run .#hi
nix run .#haloha
nix run .#hei

nix build --no-link .#legacyPackages.x86_64-linux.emacsPackages.greet
nix build --no-link .#legacyPackages.x86_64-linux.emacsPackages.hi
nix build --no-link .#legacyPackages.x86_64-linux.emacsPackages.hei
