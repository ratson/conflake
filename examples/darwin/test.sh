#!/usr/bin/env bash
set -ex

nix_build() {
  nix build --no-link --reference-lock-file flake.lock "$@"
}

nix_build .#darwinConfigurations.vm.config.system.build.toplevel
