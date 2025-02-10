#!/usr/bin/env bash
set -ex

nix_build() {
  nix build --no-link --reference-lock-file flake.lock "$@"
}

nix eval --reference-lock-file flake.lock .#lib.hello-world

nix_build .#nixosConfigurations.vm.config.system.build.vm
nix_build .#nixosConfigurations.vm-dir.config.system.build.vm
nix_build .#nixosConfigurations.vm2.config.system.build.vm

nix_build .#homeConfigurations.dummy.activationPackage

nix_build .#bonjour
nix_build .#broken-deep
