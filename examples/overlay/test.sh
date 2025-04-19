#!/usr/bin/env bash
set -ex

nix_build() {
    local ret=0
    nix build --no-link --override-input conflake ../.. --reference-lock-file flake.lock "$@" || ret=$?
    return $ret
}

nix_build .#broken 2>/dev/null || test $? -ne 0

nix_build .#broken-used
