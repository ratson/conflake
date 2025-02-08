#!/usr/bin/env bash
set -ex

nix eval .#lib.hello-world

nix build --no-link .#nixosConfigurations.vm.config.system.build.vm
nix build --no-link .#nixosConfigurations.vm-dir.config.system.build.vm
nix build --no-link .#nixosConfigurations.vm2.config.system.build.vm

nix build --no-link .#homeConfigurations.dummy.activationPackage

nix build --no-link .#packages.x86_64-linux.bonjour
