#!/usr/bin/env bash
set -ex

nix run
nix run .#greet
