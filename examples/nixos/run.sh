#!/usr/bin/env bash
set -ex

nix build --no-link .#nixosConfigurations.vm.config.system.build.vm
nix build --no-link .#nixosConfigurations.vm-dir.config.system.build.vm
nix build --no-link .#nixosConfigurations.vm2.config.system.build.vm

nix build --no-link .#homeConfigurations.dummy.activationPackage
