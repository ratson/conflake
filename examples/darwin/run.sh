#!/usr/bin/env bash
set -ex

nix build --no-link .#darwinConfigurations.vm.config.system.build.toplevel
